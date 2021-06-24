defmodule Cap.Crypto do
	
	@doc """
	Encrypt data
	
  ## Example
	
      encrypt("example test")
	"""
	def encrypt(data) do
		key = Application.get_env(:cap, :secret_key)
		iv = :crypto.strong_rand_bytes(32)
		{ct, tag} = :crypto.block_encrypt(:aes_gcm, key, iv, {"AES128GCM", data})
		Base.encode64(iv <> tag <> ct)
	end
	
	@doc """
	Decrypt data
	
  ## Example
	
      decrypt("ZV05qWlhOekluMC5rTnVZVnZpOEQ1bUc3N0FvWmdHdWhCc0NXX2luLTNEWE==")
	"""
	def decrypt(cipher) do
		key = Application.get_env(:cap, :secret_key)
		<<iv :: binary - 32, tag :: binary - 16, ct :: binary>> = Base.decode64!(cipher)
		:crypto.block_decrypt(:aes_gcm, key, iv, {"AES128GCM", ct, tag})
	end
end