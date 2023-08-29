# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity

defmodule Wug.Thai.Tokenizer do
  @moduledoc """
  Tokenizes Thai text by greedily finding the largest possible word from the
  given dictionary of words.
  """

  alias Wug.Document
  alias Wug.Thai.Dictionary
  alias Wug.Token
  alias Wug.Tokenizer

  @behaviour Wug.Tokenizer

  @typep maybe_token :: Token.t() | nil
  @typep options :: Tokenizer.options()

  @spec tokenize(Document.t(), options()) :: Document.t()
  def tokenize(doc, [dictionary: dictionary] = options) when not is_nil(dictionary) do
    characters = String.graphemes(doc.text)
    tokens = do_tokenize(characters, [], 0, Token.new(0), options)
    tokens = combine_unks(tokens)

    %{doc | tokens: tokens}
  end

  @spec do_tokenize(
          [String.t()],
          [Token.t()],
          non_neg_integer(),
          Token.t(),
          options
        ) :: [
          Token.t()
        ]
  defp do_tokenize([], tokens, index, current, _opts) do
    case current.text do
      "" -> Enum.reverse(tokens)
      _ -> tokens |> push_token(%{current | end: index - 1, type: :unk}) |> Enum.reverse()
    end
  end

  defp do_tokenize([h | t], tokens, index, current, options) do
    case parse_character(h, options) do
      {:space, _} ->
        tokens =
          case current.text do
            "" -> tokens
            _ -> push_token(tokens, %{current | end: index - 1})
          end

        tokens =
          push_token(tokens, %{Token.new(index) | text: to_string(h), end: index, type: :space})

        current = Token.new(index + 1)
        do_tokenize(t, tokens, index + 1, current, options)

      {:punctuation, punctuation} ->
        tokens =
          case current.text do
            "" -> tokens
            _ -> push_token(tokens, %{current | end: index - 1, type: :word})
          end

        tokens =
          push_token(tokens, %{Token.new(index) | text: punctuation, end: index, type: :punct})

        current = Token.new(index + 1)
        do_tokenize(t, tokens, index + 1, current, options)

      {:character, character} ->
        {token, rest} = find_word([character | t], index, options)
        length = token.text |> String.graphemes() |> Enum.count()

        tokens =
          case current.text do
            "" ->
              tokens

            _ ->
              push_token(tokens, %{current | end: current.start + length - 1})
          end

        tokens = push_token(tokens, %{token | end: index + length - 1})
        current = Token.new(index)
        do_tokenize(rest, tokens, index + length, current, options)
    end
  end

  @spec find_word([String.t()], non_neg_integer(), options) ::
          {maybe_token, [String.t()]}
  defp find_word(characters, index, dictionary: dictionary) do
    longest = do_find_word(characters, "", nil, dictionary)

    case longest do
      nil ->
        [t | remaining] = characters
        word = "" <> t

        token = %{
          Token.new(index)
          | text: word,
            type: :unk,
            end: index + String.length(word) - 1
        }

        {token, remaining}

      word ->
        token = %{
          Token.new(index)
          | text: word,
            type: :word,
            end: index + String.length(word) - 1
        }

        remaining = Enum.drop(characters, String.length(word))

        {token, remaining}
    end
  end

  defp do_find_word(remaining, prev, longest, dictionary) do
    case remaining do
      [] ->
        longest

      [char | rest] ->
        new = prev <> char

        if Dictionary.contains?(dictionary, new) || Dictionary.partial?(dictionary, new) do
          longest =
            if Dictionary.contains?(dictionary, new) do
              new
            else
              longest
            end

          do_find_word(rest, new, longest, dictionary)
        else
          longest
        end
    end
  end

  @spec is_space?(String.t()) :: boolean
  defp is_space?(string), do: String.match?(string, ~r/\s/)

  @spec is_punctuation?(String.t(), options()) :: boolean
  def is_punctuation?(character, options) do
    Enum.member?(Keyword.get(options, :punctuation, []), character)
  end

  @spec parse_character(String.t(), options) ::
          {:space, String.t()}
          | {:punctuation, String.t()}
          | {:character, String.t()}
  defp parse_character(character, options) do
    cond do
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
end
