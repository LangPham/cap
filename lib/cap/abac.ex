defmodule Cap.Abac do
	
	def apply_abac(req, resource)do
		list_check = [:show, :edit, :update, :delete]
		if req.plug_opts in list_check do
			check_abac(req, resource)
		else
			true
		end
	end
	
	defp check_abac(req, resource)do
		module = req.plug
		has_abac = Keyword.has_key?(module.__info__(:functions), :abac)
		if has_abac do
			%{"id" => id} = req.path_params
			check_id = apply(module, :abac, [id])
			value_to_string(check_id) == resource.id
		else
			true
		end
	end
	
	defp value_to_string(value) when is_integer(value), do: Integer.to_string(value)
	defp value_to_string(value), do: value

end