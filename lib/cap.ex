defmodule Cap do
	
	@moduledoc """
	Documentation for `Cap`.
	"""
	use Plug.Builder
	alias Cap.{Rbac, Abac}
	
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
		string = "id#{model.id},role#{model.role}"
		ci = Cap.Crypto.encrypt(string)
		conn
		|> put_session(:cap, ci)
	end
	
	defp apply_cap(conn, config)do
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
	
	defp not_exception(conn, config, resource, role)do
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
	
	defp get_resource(conn) do
		cap = get_session(conn, :cap)
		case cap do
			nil -> %{id: nil, role: "nil"}
			_ ->
				string_model = Cap.Crypto.decrypt(cap)
				Regex.named_captures(~r/id(?<id>\d+),role(?<role>[[:alnum:]]+)/, string_model)
				|> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
		end
	end
end
