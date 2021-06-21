defmodule Cap.Crypto do
	
	def encrypt(data) do
		key = Application.get_env(:cap, :secret_key)
		iv = :crypto.strong_rand_bytes(32)
		{ct, tag} = :crypto.block_encrypt(:aes_gcm, key, iv, {"AES128GCM", data})
		Base.encode64(iv <> tag <> ct)
	end
	
	def decrypt(cipher) do
		key = Application.get_env(:cap, :secret_key)
		<<iv :: binary - 32, tag :: binary - 16, ct :: binary>> = Base.decode64!(cipher)
		:crypto.block_decrypt(:aes_gcm, key, iv, {"AES128GCM", ct, tag})
	end
end