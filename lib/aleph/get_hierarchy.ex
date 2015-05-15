defmodule Aleph.Hierarchy do
  require Logger

  alias Aleph.ParseTurtle
  alias Aleph.ParseNTriple

  @stw ParseTurtle.run(:stw)
  @ccs ParseTurtle.run(:ccs)

  def get(:stw), do: @stw
  def get(:ccs), do: @ccs
  def get(filename) do
    case String.split(filename, ".") do
      [ name, "ttl" ] -> 
        ParseTurtle.run("#{name}.ttl")
      [ name, "n3" ] ->
        ParseNTriple.run("#{name}.n3")
      _ -> 
        Logger.debug "Porphyr.Hierarchy.get => unknown filetype"
    end
  end


end
