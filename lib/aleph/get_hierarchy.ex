defmodule Porphyr.Hierarchy do
  require Logger

  @stw Porphyr.ParseTurtle.run(:stw)
  @swp Porphyr.ParseNTriple.run(:swp)
  @ccs Porphyr.ParseTurtle.run(:ccs)

  def get(:stw), do: @stw
  def get(:swp), do: @swp
  def get(:ccs), do: @ccs
  def get(filename) do
    case String.split(filename, ".") do
      [ name, "ttl" ] -> 
        Porphyr.ParseTurtle.run("#{name}.ttl")
      [ name, "n3" ] ->
        Porphyr.ParseNTriple.run("#{name}.n3")
      _ -> 
        Logger.debug "Porphyr.Hierarchy.get => unknown filetype"
    end
  end


end
