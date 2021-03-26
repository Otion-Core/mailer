# Mailer

An email handler library based on SendGrid and Oban

## Installation

For now this is a private package that we configure in `mix.exs` via
a Git dependency:

```
{:mailer,
    git: "https://github.com/gravity-core/mailer.git", branch: "main"}
```

## Configuration

Set the appropiate Oban and Mailer configuration in your `config/config.exs`.

Eg. for `analytic`: 

```
config :my_app, Oban,
  repo: Mailer.Repo,    
  plugins: [Oban.Plugins.Pruner],    
  queues: [emails: 10]    
     
# Mailer configuration    
config :mailer, Mailer, 
  repo: Mailer.Repo,
  adapter: Mailer.SendGrid,
  # default sender configuration (optional)
  sender: [
    name: "John C.",
    email: "john.c@farscape.fake.com"
  ],
  # Warn if emails are enabled (Use with Mailer.warn_if_enabled())
  warn_if_enabled: true
```

Add Oban to your supervision tree in your application `start/2` callback:

```
children = [
  Repo,
  Endpoint,
  {Oban, oban_config()}
]
```

Setup your repo to use pagination:

```
defmodule Analytic.Repo do
  use Ecto.Repo,
    otp_app: :my_app,                        
    adapter: Ecto.Adapters.Postgres
              
  use Scrivener, page_size: 10                                                                                                                                                                                               
end 
```

Define migrations for both Oban and Mailer:

```
defmodule Analytic.Repo.Migrations.AddOban do
  use Ecto.Migration

  def up do
    Oban.Migrations.up()
  end

  def down do
    Oban.Migrations.down(version: 1)
  end
end

defmodule Analytic.Repo.Migrations.AddMailer do
  use Ecto.Migration

  def up do
    Mailer.Migrations.up()
  end

  def down do
    Mailer.Migrations.down()
  end
end
```

then migrate your database with `mix ecto.migrate`


## Environment variables

The following environment variables are supported:

| name | description
| --- | --- |
| `ENABLE_EMAILS` | whether or not actually send emails to the provider (useful for development) |
| `SENDGRID_TOKEN` | SendGrid's api token


## Usage:

### Warning if emails are enabled

1. Check that `warn_if_enabled` is set to `true` in your application environment (see above)
2. Call `Mailer.warn_if_enabled()` during application startup

### Compose your email:
 
 ```
alias Mailer.Email
email = Email.new()
     |> Email.from(name: "Mrs Foo", email: "foo@foo.com") 
     |> Email.to(name: "Mrs Bar", email: "bar@bar.com")
     |> Email.to(name: "Mr Baz", email: "baz@baz.com")
     |> Email.subject("Hello")
     |> Email.template("...")
     |> Email.value("some_value", "value")
     |> Email.value("some_other", "value")
```

### Send it:

```
:ok = Mailer.send(email) 
```

### Check its status:

```
{:ok, email} = Mailer.get(email.id)
IO.puts(email.status)
```

### Find emails by status:    
    
```    
%Scrivener.Page{entries: entries} = Mailer.find_by(status: :sent)    
``` 

### Delete old emails    
    
```    
:ok = Mailer.prune()    
```

## Features

- [x] Emails are processed as Oban jobs. Errors are automatically retried by Oban (3 times by default)
- [x] Status for each email is also tracked in the `emails` table.
- [x] Two env variables are supported: `ENABLE_EMAILS` and `SENDGRID_TOKEN`
- [x] Provides with both Oban and Mailer level telemetry
- [x] It is possible to prune old emails (emails that have been already processed) 
- [ ] Supports attachments
- [ ] Implement a retry api, ie `Mailer.retry(email.id)` that only re-attempts emails that are in state `:error` ?
- [ ] Handle email priorities

