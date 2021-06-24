# Cap
![Hex.pm](https://img.shields.io/hexpm/l/cap)
![Hex.pm](https://img.shields.io/hexpm/v/cap)

Cap is Central Authentication Plug for Phoenix, access control library with Role-based access control (RBAC) and Attribute-based access control (ABAC)

## How to use

Add the package as a dependency in your Elixir project using something along the lines of:

```elixir
def deps do
  [
    {:cap, "~> 0.1.0"}
  ]
end
```

In your configuration you can set values for RBAC directly, eg
```elixir
config :cap,
       effect: :deny,         
       #Allow Root to any
       exception: :root, 
       policy: %{
         nil: %{
           # Deny Anonymous use to any action in any Controller
           :* => :* 
         },
         admin: %{
           # Deny Admin use to any action in UserController
           ThetaWeb.UserController => :* 
         }, 
         mod: %{
           # Deny Mod use to action :update and :delete in ArticleController
           ThetaWeb.CMS.ArticleController => [:update, :delete],
           # Deny Mod use to any action in UserController
           ThetaWeb.UserController => :*
         },
         user: %{
           # Deny User use to any action in any Controller
		   :* => :*
         },
       },
       # secret_key for encrypt, decrypt value in session
       secret_key: "AMlTnnYyOp3EWUbwSTawScMyF9IQoVYs" 
```

Add plug to scope in pipeline

```elixir
pipeline :admin do
    plug :put_layout, {ThetaWeb.LayoutView, "layout_admin.html"}
    plug Cap
end
```

Apply pipeline in scope
```elixir
scope "/admin", ThetaWeb do
    pipe_through [:browser, :admin]
    resources "/users", UserController    
    resources "/article", CMS.ArticleController
end
```

Add resource for session
```elixir
defmodule ThetaWeb.SessionController do
  use ThetaWeb, :controller

  import Cap
  alias Theta.Account  
  
  ...
  
  def create(
        conn,
        %{
          "user" => %{
            "email" => email,
            "password" => password
          }
        }
      ) do
    case Account.authenticate_by_email_password(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome #{user.name}!")
        |> Cap.sign_in(user.id, user.role) # Add id and role into session           
        |> redirect(to: "/user/me")
      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, "Bad email/password combination")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end

  def delete(conn, _) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end

```

Apply ABAC in for controller:
```elixir
defmodule ThetaWeb.CMS.ArticleController do
  use ThetaWeb, :controller
  
  alias Theta.CMS
  
  ...
  
  # id in param of func :show, :edit, :update, :delete
  def abac(id) do
	  article = CMS.get_article!(id)
	  article.author_id # compare with id in Cap sign_in
  end

end
```

Implement Plug.Exception for Cap.ErrorHandler
```elixir
defimpl Plug.Exception, for: Cap.ErrorHandler do
  def status(exception) do
    case Integer.parse(exception.message) do
      :error -> 404
      {int, _} -> 403
    end
  end
end
```



