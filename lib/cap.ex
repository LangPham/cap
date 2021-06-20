defmodule Cap do

  @moduledoc """
  Documentation for `Cap`.
  """
  use Plug.Builder

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

  def sign_in(conn, model) do
    #    IO.inspect model, label: "MODEL CAP====\n"
    string = "id#{model.id},role#{model.role}"
    ci = encrypt(string)
    conn
    |> put_session(:cap, ci)
  end

  defp get_resource(conn) do
    cap = get_session(conn, :cap)
    case cap do
      nil -> %{id: nil, role: "nil"}
      _ ->
        string_model = decrypt(cap)
        Regex.named_captures(~r/id(?<id>\d+),role(?<role>[[:alnum:]]+)/, string_model)
        |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
    end
  end

  defp apply_cap(conn, config)do
    # Todo: get role
    resource = get_resource(conn)

    role =
      String.downcase(resource.role)
      |> String.to_atom()
    IO.inspect role, label: "ROLE ====\n"
    router = conn.private.phoenix_router
    policy = config[:policy]
    effect = config[:effect] == :allow
    req = Phoenix.Router.route_info(router, conn.method, conn.request_path, conn.host)

    IO.inspect effect, label: "Effect==============\n"
    IO.inspect policy, label: "Policy==============\n"
    IO.inspect req, label: "Request==============\n"

    case {effect, Map.has_key?(policy, role)} do
      {true, true} ->
        # Allow have policy => check
        matchers(conn, req, policy[role], effect)
      {true, false} ->
        # Allow not policy => not permission
        error_403(conn)
      {false, true} ->
        # Deny have policy => check
        matchers(conn, req, policy[role], effect)
      {_, _} ->
        # Deny not policy => ok
        conn
    end
  end

  defp matchers(conn, req, policy, effect) do
    has_policy =
      case Map.has_key?(policy, :*) do
        true -> true
        _ ->
          case Map.has_key?(policy, req.plug) do
            true ->
              regex = create_regex(policy[req.plug])
              Regex.match?(regex, "#{req.plug_opts}")
            _ -> false
          end
      end

    case effect == has_policy do
      true -> conn
      _ -> error_403(conn)
    end
  end

  defp error_403(conn) do
    conn
    |> put_status(403)
    |> send_resp(403, "Unauthorized")
    |> halt
  end

  defp create_regex(action) when is_list(action) do
    ~r/#{~s/(#{Enum.join(action, "|")})/}/
  end
  defp create_regex(action) when is_atom(action) do
    case action do
      :* -> ~r//
      atom -> ~r/#{atom}/
    end
  end
  defp create_regex(_), do: ~r//

  defp encrypt(data) do
    key = Application.get_env(:cap, :secret_key)
    iv = :crypto.strong_rand_bytes(32)
    {ct, tag} = :crypto.block_encrypt(:aes_gcm, key, iv, {"AES128GCM", data})
    Base.encode64(iv <> tag <> ct)
  end

  defp decrypt(cipher) do
    key = Application.get_env(:cap, :secret_key)
    <<iv :: binary - 32, tag :: binary - 16, ct :: binary>> = Base.decode64!(cipher)
    :crypto.block_decrypt(:aes_gcm, key, iv, {"AES128GCM", ct, tag})
  end

end
