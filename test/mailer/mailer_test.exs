defmodule MailerTest do
  use Mailer.TestCase
  alias Mailer
  alias Mailer.Backlog
  alias Mailer.Email

  import ExUnit.CaptureLog

  defp test_email do
    Email.new()
    |> Email.from(name: "Mrs Foo", email: "foo@bar.com")
    |> Email.to(name: "Mr Foo", email: "foo@bar.com")
    |> Email.subject("test")
    |> Email.template("test_template")
    |> Email.value("foo", "bar")
  end

  test "warns if tests are enabled" do
    env = Application.get_env(:mailer, Mailer)

    new_env = Keyword.put(env, :warn_if_enabled, true)
    assert :ok == Application.put_env(:mailer, Mailer, new_env)
    System.put_env("ENABLE_EMAILS", "true")

    assert capture_log(fn ->
             Mailer.warn_if_enabled()
           end) =~ "CAUTION"

    new_env = Keyword.delete(env, :warn_if_enabled)
    assert :ok == Application.put_env(:mailer, Mailer, new_env)

    assert "" ==
             capture_log(fn ->
               Mailer.warn_if_enabled()
             end)
  end

  test "does not allow invalid emails" do
    email = Email.new()
    {:error, :invalid} = Mailer.send(email)
    refute_enqueued(worker: Backlog, args: %{id: email.id})
  end

  test "keeps track of emails sent successfully" do
    System.put_env("ENABLE_EMAILS", "true")

    email = test_email()
    assert :ok == Mailer.send(email)

    result = Mailer.send(email)
    {:error, _} = result

    assert_enqueued(worker: Backlog, args: %{id: email.id})
    assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :emails)

    {:ok, email} = Mailer.get(email.id)
    assert :sent == email.status

    %{entries: entries} = Mailer.find_by(status: :sent)
    assert 1 == length(entries)

    [found] = entries
    assert email.id == found.id
  end

  test "supports a debug mode" do
    System.put_env("ENABLE_EMAILS", "false")

    email = test_email()

    result = Mailer.send(email)
    assert :ok == result

    assert_enqueued(worker: Backlog, args: %{id: email.id})
    assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :emails)

    {:ok, email} = Mailer.get(email.id)

    assert :processed == email.status

    %{entries: entries} = Mailer.find_by(status: :processed)
    assert 1 == length(entries)

    [found] = entries
    assert email.id == found.id
  end

  test "keeps track of connecting errors" do
    System.put_env("ENABLE_EMAILS", "true")

    email =
      test_email()
      |> Email.subject("connect error")

    result = Mailer.send(email)
    assert :ok == result

    assert_enqueued(worker: Backlog, args: %{id: email.id})
    assert %{success: 0, failure: 1} = Oban.drain_queue(queue: :emails)

    {:ok, email} = Mailer.get(email.id)
    assert :error == email.status
    assert email.error =~ "connect error"

    %{entries: entries} = Mailer.find_by(status: :error)
    assert 1 == length(entries)
    [found] = entries
    assert email.id == found.id
  end

  test "paginates email result" do
    System.put_env("ENABLE_EMAILS", "true")

    1..20
    |> Enum.each(fn _ ->
      email = test_email()

      result = Mailer.send(email)
      assert :ok == result
    end)

    assert %{success: 20, failure: 0} = Oban.drain_queue(queue: :emails)

    %{entries: entries} = Mailer.find_by(status: :sent, page: 1)
    assert 10 == length(entries)

    %{entries: entries} = Mailer.find_by(status: :sent, page: 2)
    assert 10 == length(entries)
  end

  test "emails are returned in descending order" do
    System.put_env("ENABLE_EMAILS", "true")

    email1 = test_email()
    assert :ok == Mailer.send(email1)

    Process.sleep(1000)

    email2 = test_email()
    assert :ok == Mailer.send(email2)

    assert %{success: 2, failure: 0} = Oban.drain_queue(queue: :emails)

    %{entries: entries} = Mailer.find_by(status: :sent)
    assert 2 == length(entries)
    [found1, found2] = entries
    assert email2.id == found1.id
    assert email1.id == found2.id
  end

  test "prunes old emails" do
    email = test_email()
    assert :ok == Mailer.send(email)

    {:ok, found} = Mailer.get(email.id)
    assert found.id == email.id

    assert :ok = Mailer.prune()
    {:ok, found} = Mailer.get(email.id)
    assert found.id == email.id

    assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :emails)

    assert :ok = Mailer.prune()
    assert {:error, :not_found} = Mailer.get(email.id)
  end

  test "supports a default sender" do
    env = Application.get_env(:mailer, Mailer)

    assert :ok ==
             Application.put_env(:mailer, Mailer, Keyword.put(env, :sender, nil))

    email = Email.new()
    refute email.data[:from]

    default_sender = [name: "John C", email: "john.c@farscape.fake.com"]

    new_env = Keyword.put(env, :sender, default_sender)

    assert :ok == Application.put_env(:mailer, Mailer, new_env)

    assert default_sender == Application.get_env(:mailer, Mailer)[:sender]

    email = Email.new()
    assert default_sender[:name] == email.data["from"]["name"]
    assert default_sender[:email] == email.data["from"]["email"]
  end
end
