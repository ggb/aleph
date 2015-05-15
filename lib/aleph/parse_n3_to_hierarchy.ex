defmodule Aleph.ParseNTriple do
  require Logger
  
  alias Aleph.HierarchyNode
  
  @lang "en"
    
  defp prepare_identifier(s) do
    String.replace(s, ["<", ">"], "")
  end
  
  defp prepare_label(s) do
    s
    |> String.downcase
    |> String.replace(["\"", "\""], "")
  end
  
  defp prepare_relation(s) do
    String.replace(s, ["<", ">", "http://www.w3.org/2004/02/skos/core#"], "")
  end  
  
  def parse_line(single) do    
    case String.split(single, ["> ", "@", " ."]) do
      [subj, praed, obj, @lang, ""] ->
        { :ok, { prepare_identifier(subj), prepare_relation(praed), prepare_label(obj) } }
      [_subj, _praed, _obj, _, ""] -> 
        { :empty }      
      [subj, praed, obj, "."] -> 
        { :ok, { prepare_identifier(subj), prepare_relation(praed), prepare_identifier(obj) } }      
      _ -> 
        Logger.debug "Unexpected pattern in line: " <> single
        { :empty }
    end    
  end
  
  defp update_helper("broader", val, hNode), do: %{ hNode | broader: [ val | hNode.broader] }
  defp update_helper("related", val, hNode), do: %{ hNode | related: [ val | hNode.related] }
  defp update_helper("narrower", val, hNode), do: %{ hNode | narrower: [ val | hNode.narrower ] }
  defp update_helper("prefLabel", val, hNode), do: %{ hNode | prefLabel: val }
  defp update_helper("altLabel", val, hNode), do: %{ hNode | altLabel: [ val | hNode.altLabel ] }
  defp update_helper(relation, _val, hNode) do
    Logger.debug "Unknown relation: " <> relation
    hNode
  end
    
  def to_hierarchy({ identifier, relation, value }, dict) do
    if Dict.has_key?(dict, identifier) do
      Dict.update!(dict, identifier, fn hNode -> update_helper(relation, value, hNode) end)
    else
      Dict.put_new(dict, identifier, update_helper(relation, value, %HierarchyNode{ identifier: identifier }) )
    end
  end
    
  def run(path) do
    path
    |> File.read!
    |> String.split("\n", trim: true)
    |> Enum.reduce([], fn ele, acc -> 
      case parse_line(ele) do
        { :ok, val } -> 
          [ val | acc ]
        { :empty } ->
          acc                
      end    
    end)
    |> Enum.reduce(HashDict.new, &to_hierarchy/2)
  end  
  
end
