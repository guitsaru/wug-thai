# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

defmodule Wug.Thai.Tokenizer do
  @moduledoc """
  Tokenizes Thai text by greedily finding the largest possible word from the
  given dictionary of words.
  """

  alias Wug.Document
  alias Wug.Scanner
  alias Wug.Thai.Dictionary
  alias Wug.Token
  alias Wug.Tokenizer

  @behaviour Wug.Tokenizer

  @typep maybe_token :: Token.t() | nil
  @typep options :: Tokenizer.options()

  @spec tokenize(Document.t(), options()) :: Document.t()
  def tokenize(doc, [dictionary: dictionary] = options) when not is_nil(dictionary) do
    characters = String.graphemes(doc.text)
    scanner = Scanner.new(characters)
    tokens = do_tokenize(scanner, [], options)
    tokens = combine_unks(tokens)

    %{doc | tokens: tokens}
  end

  @spec do_tokenize(
          Scanner.t(),
          [Token.t()],
          options
        ) :: [
          Token.t()
        ]
  defp do_tokenize(scanner, tokens, options) do
    {current, scanner} = Scanner.next(scanner)

    parse_current(current, scanner, tokens, options)
  end

  defp parse_current(nil, _, tokens, _), do: Enum.reverse(tokens)

  defp parse_current(char, scanner, tokens, options) do
    case parse_character(char, options) do
      {:token, _} ->
        {token, scanner} = find_token(scanner, options)
        tokens = push_token(tokens, %{token | end: scanner.pointer - 1})
        do_tokenize(scanner, tokens, options)

      {:space, _} ->
        tokens =
          push_token(tokens, %{
            Token.new(scanner.pointer)
            | text: to_string(char),
              end: scanner.pointer,
              type: :space
          })

        do_tokenize(scanner, tokens, options)

      {:punctuation, punctuation} ->
        tokens =
          push_token(tokens, %{
            Token.new(scanner.pointer)
            | text: punctuation,
              end: scanner.pointer,
              type: :punct
          })

        do_tokenize(scanner, tokens, options)

      {:character, _} ->
        {token, scanner} = find_word(scanner, options)

        tokens = push_token(tokens, %{token | end: scanner.pointer})
        do_tokenize(scanner, tokens, options)
    end
  end

  @spec find_word(Scanner.t(), options) ::
          {maybe_token, Scanner.t()}
  defp find_word(scanner, dictionary: dictionary) do
    index = scanner.pointer
    word = do_find_word(scanner, index, [], dictionary)

    case word do
      nil ->
        word = "" <> Scanner.current(scanner)

        token = %{
          Token.new(index)
          | text: word,
            type: :unk,
            end: index
        }

        {token, scanner}

      word ->
        length = String.length(word)

        token = %{
          Token.new(index)
          | text: word,
            type: :word,
            end: index + length - 1
        }

        {token, Scanner.set_pointer(scanner, index + length - 1)}
    end
  end

  defp do_find_word(scanner, starting_index, choices, dictionary) do
    character = Scanner.current(scanner)

    if character do
      word =
        Scanner.slice(scanner, starting_index, scanner.pointer - starting_index + 1)
        |> Enum.join()

      choices =
        if Dictionary.contains?(dictionary, word) &&
             can_start_a_token?(Scanner.peek(scanner), dictionary: dictionary) do
          frequency = Dictionary.get_frequency(dictionary, word)
          [{word, frequency} | choices]
        else
          choices
        end

      if Dictionary.partial?(dictionary, word) do
        {_, scanner} = Scanner.next(scanner)
        do_find_word(scanner, starting_index, choices, dictionary)
      else
        pick_choice(choices)
      end
    else
      pick_choice(choices)
    end
  end

  defp find_token(scanner, _opts) do
    token = %{Token.new(scanner.pointer) | text: "", type: :word}

    do_find_token(scanner, token)
  end

  defp do_find_token(scanner, token) do
    case Scanner.next(scanner) do
      {"}", scanner} ->
        {token, scanner}

      {nil, scanner} ->
        {token, scanner}

      {other, scanner} ->
        token = %{token | text: token.text <> other, end: scanner.pointer}
        do_find_token(scanner, token)
    end
  end

  @spec pick_choice([{String.t(), float()}]) :: String.t() | nil
  defp pick_choice(choices) do
    choices
    |> Enum.map(fn {word, frequency} ->
      length = String.length(word) / 10
      score = Enum.sum([length, frequency ** 0.1]) / 2
      {word, score}
    end)
    |> Enum.sort_by(&elem(&1, 1), :desc)
    |> List.first()
    |> case do
      nil -> nil
      {word, _} -> word
    end
  end

  @spec is_space?(String.t()) :: boolean
  defp is_space?(string), do: String.match?(string, ~r/\s/)

  @spec is_punctuation?(String.t(), options()) :: boolean
  def is_punctuation?(character, options) do
    Enum.member?(Keyword.get(options, :punctuation, []), character)
  end

  @spec is_thai?(String.t()) :: boolean
  def is_thai?(string) do
    string
    |> String.to_charlist()
    |> Enum.all?(&(&1 in 0x0E00..0x0E7F))
  end

  @spec parse_character(String.t(), options) ::
          {:space, String.t()}
          | {:punctuation, String.t()}
          | {:character, String.t()}
  defp parse_character(character, options) do
    cond do
      character == "{" -> {:token, character}
      is_space?(character) -> {:space, character}
      is_punctuation?(character, options) -> {:punctuation, character}
      true -> {:character, character}
    end
  end

  @spec push_token([Token.t()], maybe_token) :: [Token.t()]
  defp push_token(acc, token) do
    [token | acc]
  end

  defp combine_unks(tokens) do
    Enum.reduce(tokens, [], fn token, acc ->
      case {token.type, acc} do
        {:unk, []} ->
          [token | acc]

        {:unk, [prev | rest]} ->
          if prev.type == :unk do
            [%{prev | text: prev.text <> token.text, end: token.end} | rest]
          else
            [token | acc]
          end

        _ ->
          [token | acc]
      end
    end)
    |> Enum.reverse()
  end

  @spec can_start_a_token?(String.t() | nil, options) :: boolean
  defp can_start_a_token?(nil, _options), do: true

  defp can_start_a_token?(character, dictionary: dictionary) do
    !is_thai?(character) || Dictionary.partial?(dictionary, character)
  end
end
