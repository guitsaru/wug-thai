defmodule Wug.Thai.Dictionary do
  @moduledoc false

  @default_dictionary_file "../../../data/words_th.txt"

  @derive {Inspect, only: [:count]}
  defstruct count: 0, data: %{}

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          data: map()
        }

  @spec new(String.t()) :: t()
  def new(path \\ @default_dictionary_file) do
    __DIR__
    |> Path.join(path)
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Enum.reduce(%__MODULE__{}, fn word, dictionary ->
      add(dictionary, word)
    end)
  end

  @spec add(t(), String.t()) :: t()
  def add(dictionary, word) when is_binary(word) do
    characters = String.graphemes(word)

    data = insert(dictionary.data, characters)

    %{dictionary | data: data, count: dictionary.count + 1}
  end

  @spec contains?(t(), String.t()) :: boolean
  def contains?(dictionary, word) when is_binary(word) do
    characters = String.graphemes(word)

    value = get_in(dictionary.data, characters)

    cond do
      value == true -> true
      is_map(value) -> Map.has_key?(value, true)
      true -> false
    end
  end

  @spec partial?(t(), String.t()) :: boolean
  def partial?(dictionary, word) do
    characters = String.graphemes(word)

    !!get_in(dictionary.data, characters)
  end

  @spec insert(map, [String.t()]) :: map
  defp insert(map, [next | rest]) do
    {_, new} =
      Map.get_and_update(map, next, fn current ->
        case current do
          nil -> {current, insert(%{}, rest)}
          map -> {map, insert(map, rest)}
        end
      end)

    new
  end

  defp insert(map, []) do
    Map.put(map, true, true)
  end
end
