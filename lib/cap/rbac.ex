defmodule Cap.Rbac do
	
	def apply_rbac(effect, policy, role, req)do
		case {effect, Map.has_key?(policy, role)} do
			{true, true} ->
				# Allow have policy => check
				matchers(req, policy[role], effect)
			{false, true} ->
				# Deny have policy => check
				matchers(req, policy[role], effect)
			{true, false} ->
				# Allow not policy => not permission
				false
			{false, false} ->
				# Deny not policy => ok
				true
		end
	end
	
	defp matchers(req, policy, effect) do
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
		
		effect == has_policy
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
	
end