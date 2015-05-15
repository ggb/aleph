defmodule Aleph.VocabluaryTrie do
  require Logger
  
  alias Aleph.ParseVocabluary
  alias Aleph.ParseTurtle
  
  @length_threshold 1
  
  # Switches the position in the tuple as follows:
  #   { id, synonym } => { synonym, id }
  # and changes strings to char-lists. This is necessary for correct processing 
  # by the external trie library.
  defp prepare([], newlist), do: newlist
  defp prepare([ {fst, scd} | tail ], newlist) do
    prepare(tail, [ {String.to_char_list(scd), fst } | newlist])
  end

  def get_vocabluary(:stw) do
    ParseTurtle.run("stw.ttl")
    |> get_vocabluary
  end
  
  def get_vocabluary(:ccs) do
    ParseTurtle.run("ccs.ttl")
    |> get_vocabluary
  end
  
  @doc """

  """
  def get_vocabluary(hierarchy) do
    hierarchy 
    |> Enum.map(fn { ident, hNode } -> 
      # get all labels
      [ hNode.prefLabel | hNode.altLabel ]
      # create tuples
      |> Enum.map(fn label -> 
        { ident, label }
      end) 
    end)
    # flatten result
    |> List.flatten
    |> Enum.filter(fn { _ident, syn } -> syn != "" end)
    # switch positions
    |> prepare([])
    # and create the trie
    |> :trie.new
  end
    
end
