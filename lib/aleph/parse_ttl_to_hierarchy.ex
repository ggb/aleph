defmodule Aleph.ParseTurtle do
  require Logger
  alias Aleph.HierarchyNode
  
  @lang "en"
  
  defp prepare_word(word) do
    word 
    # remove special characters and language annotations
    |> String.replace(~r/@en|\.|;|\"|\<|\>|'/, "") 
    |> String.downcase 
    # remove preceding STW version notes
    # |> String.replace(~r/\w\d+\s/, "")
    # ... and brackets
    |> String.replace(~r/\s\(.+\)/, "")
    |> String.strip 
  end
  
  defp prepare_labels(elements) do
    elements
    |> String.split(",", trim: true) 
    |> Enum.filter(fn word -> String.contains?(word, "@" <> @lang) end) 
    |> Enum.map(fn word -> prepare_word(word) end)
  end
  
  defp prepare_list(elements) do
    elements
    |> String.split(",", trim: true) 
    |> Enum.map(fn word -> prepare_word(word) end)
  end
   
  defp build_callback([ "skos:related" <> elements | rest ], hnode) do
    build_callback(rest, %{ hnode | related: prepare_list(elements) })  
  end
  
  defp build_callback([ "skos:broader" <> elements | rest ], hnode) do
    build_callback(rest, %{ hnode | broader: prepare_list(elements) })  
  end
  
  defp build_callback([ "skos:narrower" <> elements | rest ], hnode) do
    build_callback(rest, %{ hnode | narrower: prepare_list(elements) })  
  end
  
  defp build_callback([ "skos:altLabel" <> elements | rest ], hnode) do
    build_callback(rest, %{ hnode | altLabel: prepare_labels(elements) })
  end
  
  defp build_callback([ "skos:prefLabel" <> elements | rest ], hnode) do
    build_callback(rest, %{ hnode | prefLabel: prepare_labels(elements) |> hd })  
  end
  
  defp build_callback([ _head | rest ], hnode), do: build_callback(rest, hnode)
  defp build_callback([], hnode), do: hnode
    
  defp build_node(block) do
    hnode = %HierarchyNode{}
    build_callback(tl(block), %{ hnode | identifier: hd(block) |> prepare_word })
  end
  
  def to_vocabluary(dict) do
    dict 
    |> Enum.map(fn { ident, hnode } -> [ { ident, hnode.prefLabel } | Enum.map(hnode.altLabel, fn aLabel -> { ident, aLabel} end) ] end)
    |> List.flatten
    # we don't need hyphens, but we keep a blank
    |> Enum.map(fn { ident, phrase } -> { ident, String.replace(phrase, "-", " ") } end)
  end
  
  def run(:stw), do: run("stw.ttl")
  def run(:ccs), do: run("ccs.ttl")
  
  def run(path) do
    path
    |> File.read!
    |> String.split("\n\n", trim: true)
    |> Enum.map(fn el -> 
         String.split(el, "\n") |> Enum.map(fn word -> String.strip(word) end) 
       end)
    |> tl
    |> Enum.map(fn block -> build_node(block) end)
    |> Enum.filter(fn hnode -> hnode.prefLabel != "" and hnode.identifier != "" end)
    |> Enum.map(fn hnode -> { hnode.identifier, hnode } end)
    |> Enum.into(HashDict.new)
  end

end
