require Protocol
Protocol.derive(Jason.Encoder, Tesla.Env, except: [:__client__])

defimpl Jason.Encoder, for: Tuple do
  def encode(data, options) when is_tuple(data) do
    data
    |> Tuple.to_list()
    |> Jason.Encoder.List.encode(options)
  end
end
