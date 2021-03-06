defmodule Cap do
  @moduledoc """
  Documentation for `Cap`.
  """
  use Plug.Builder
  alias Cap.{Rbac, Abac, Crypto}

  def init(opts) do
    Keyword.merge(Application.get_all_env(:cap), opts)
  end

  def call(conn, opts) do
    check_config = Keyword.has_key?(opts, :policy) && Keyword.has_key?(opts, :effect)

    case check_config do
      true -> apply_cap(conn, opts)
      _ -> conn
    end
  end

  @doc """
  Call sign_in in controller login to put session.

   ## Example

       Cap.sign_in(conn, id, role)

  """
  def sign_in(conn, id, role) do
    string = %{id: id, role: role}

    conn
    |> put_session(:cap, string)
    |> configure_session(renew: true)
  end

  @doc """
  Verify password.

  ## Example
      iex>  Cap.verify_pwd("password", "9+757UiM5YnNcyQKtgCPx9IJb2pjv8sJgxCBQqC9kX0")
      true
  """
  def verify_pwd(pass, hash) do
    Crypto.verify_sha(pass, hash)
  end

  @doc """
  Hash password.

  ## Example
      iex>  Cap.hash_pwd("password")
      "9+757UiM5YnNcyQKtgCPx9IJb2pjv8sJgxCBQqC9kX0"
  """
  def hash_pwd(pass) do
    Crypto.encrypt_sha(pass)
  end

  defp apply_cap(conn, config) do
    resource = get_resource(conn)

    role =
      String.downcase(resource.role)
      |> String.to_atom()

    exception = config[:exception]

    if exception != nil and role == exception do
      conn
    else
      not_exception(conn, config, resource, role)
    end
  end

  defp not_exception(conn, config, resource, role) do
    router = conn.private.phoenix_router
    policy = config[:policy]
    effect = config[:effect] == :allow
    req = Phoenix.Router.route_info(router, conn.method, conn.request_path, conn.host)

    rbac = Rbac.apply_rbac(effect, policy, role, req)
    abac = Abac.apply_abac(req, resource)

    case rbac and abac do
      true -> conn
      _ -> raise Cap.ErrorHandler, "403"
    end
  end

  @doc """
  Get resource.

  ## Example

      Cap.get_resource(conn)
  	  %{id: 1, role: "ROOT"}
  """
  def get_resource(conn) do
    cap = get_session(conn, :cap)

    case cap do
      nil -> %{id: nil, role: "nil"}
      _ -> cap
    end
  end
end
