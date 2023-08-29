defmodule Wug.Array do
  @moduledoc "A data structure for constant time lookup of lists."

  @opaque t :: %__MODULE__{
            data: map(),
            length: non_neg_integer()
          }

  defstruct length: 0, data: %{}

  @spec new :: t()
  def new, do: new([])

  @spec new(List.t()) :: t()
  def new(list) do
    data =
      list
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {item, index}, data ->
        Map.put(data, index, item)
      end)

    %__MODULE__{data: data, length: Enum.count(list)}
  end

  @spec get(t(), non_neg_integer()) :: any
  def get(array, index) do
    Map.get(array.data, index)
  end
end
