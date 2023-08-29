defmodule Wug.Thai.Dictionary do
  @moduledoc false

  @default_dictionary_file "../../../data/words_th.txt"
  @default_frequency_file "../../../data/tnc_freq.txt"
  @external_resource @default_dictionary_file
  @external_resource @default_frequency_file

  @derive {Inspect, only: [:count]}
  defstruct count: 0, data: %{}

  @type t :: %__MODULE__{
          count: non_neg_integer(),
          data: map()
        }

  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @spec default() :: t()
  def default do
    frequencies = load_frequencies()
    max = frequencies |> Map.values() |> Enum.max()

    __DIR__
    |> Path.join(@default_dictionary_file)
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Enum.reduce(%__MODULE__{}, fn word, dictionary ->
      frequency = Map.get(frequencies, word, 0)
      add(dictionary, word, frequency / max)
    end)
  end

  @spec add(t(), String.t(), float()) :: t()
  def add(dictionary, word, frequency \\ 0.0) when is_binary(word) do
    characters = String.graphemes(word)

    data = insert(dictionary.data, characters, frequency)

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

  @spec get_frequency(t(), String.t()) :: float()
  def get_frequency(dictionary, word) when is_binary(word) do
    characters = String.graphemes(word)

    value = get_in(dictionary.data, characters)

    cond do
      value == true -> 1.0
      is_map(value) -> Map.get(value, true, 0.0)
      true -> 0.0
    end
  end

  @spec insert(map, [String.t()], any) :: map
  defp insert(map, [next | rest], value) do
    {_, new} =
      Map.get_and_update(map, next, fn current ->
        case current do
          nil -> {current, insert(%{}, rest, value)}
          map -> {map, insert(map, rest, value)}
        end
      end)

    new
  end

  defp insert(map, [], value) do
    Map.put(map, true, value)
  end

  defp load_frequencies do
    __DIR__
    |> Path.join(@default_frequency_file)
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Enum.reduce(%{}, fn line, frequencies ->
      [word, count] = String.split(line, "\t")

      Map.put(frequencies, String.trim(word), String.to_integer(count))
    end)
  end
end
