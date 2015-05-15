defmodule Aleph.Entities do
  require Logger
  
  @min_word_length 4
  
  @stwvoc Porphyr.VocabluaryTrie.get_vocabluary(:stw)  
  @swpvoc Porphyr.VocabluaryTrie.get_vocabluary(:swp)
  @ccsvoc Porphyr.VocabluaryTrie.get_vocabluary(:ccs)
  # does not work as module attribute - why?
  # @marks_pattern :binary.compile_pattern([".", ",", ":", ";", "!", "?", "\n", "(", ")", "'", "\"", "\t"])

  # defp debug_str(input, msg) do
  #   Logger.debug msg
  #   input
  # end
    
  @doc """
  Gets a binary.
  Prepares the text: Puts everything in lower case; removes special characters, line breaks, etc.
  Than splits up the text by spaces and returns a list of words.  
  """
  def prep_text(text) do
    # Logger.debug "Preparing text"
    
    pattern = :binary.compile_pattern([".", ",", ";", "!", "?", "\n", "(", ")", "'", "\"", "\t"])
    text
    # doing the downcase at this point seems to be a good idea... IT IS NOT! 
    # it causes the vm to crash, although I have no idea, why (looks like a bug...)
    #
    # |> debug_str("before downcase") 
    # |> String.downcase  
    |> String.replace(pattern, "")
    |> String.split(" ", trim: true)
  end
    
  # Gets a list of tuples, where the first element in the tuple is a string. It calculates
  # the string-length, sorts the list by the length and returns the head of the list (it is
  # the longest hit).
  defp longest_match(list) do
    list 
    |> Enum.sort(fn { fst, _ }, { scd, _ } -> length(fst) > length(scd) end)
    |> hd
  end
  
  @doc """
  Recursion anchor: Returns the entities, if there are only two words (or less) left in the list.   
  """
  # TODO Aktuell werden die letzten zwei Worte für die Ermittlung von Entitäten nicht berücksichtigt.
  def detect(list, _vocabluary, entities) when length(list) <= 2 do
    entities  
  end
  
  @doc """
  Gets a list of words, a vocabluary and a list of entities.
  Searches for a match for the first elements of the list in the vocabluary; if there are hits
  the longest match is added to the list of entities.
  """
  def detect([ head | [ scd | [ thd | rest ] ] ], vocabluary, entities) do
    # checks, if there is a hit for the combination of the first three words in the trie
    result = "#{head} #{scd} #{thd}"
    # moved the String.downcase to this place; see comment in method prep_text
    |> String.downcase
    |> String.to_char_list
    |> :trie.find_prefixes(vocabluary)
    |> Enum.filter(fn { word, _ident } -> length(word) >= @min_word_length end)
    
    if result == [] do
      # if the result set is empty, trie the next word and keep everything else as it is
      detect([ scd | [ thd | rest ]], vocabluary, entities)
    else
      # else: calculate the longest match
      { result_fst, result_scd } = longest_match(result)
      # transform the result into a two element list of strings
      hit = [ to_string(result_fst), to_string(result_scd) ]
      # Logger.debug "#{result_fst}, #{result_scd}"
      
      # calculate the word-length of the hit and move the "window"
      # e. g.: is the hit is two words long, skip the current head and second element
      #        to avoid redundancy
      case length(String.split(to_string(result_fst), " ")) do
          3 -> detect(rest, vocabluary, [ hit | entities ])
          2 -> detect([ thd | rest ], vocabluary, [ hit | entities ])
          _ -> detect([ scd | [ thd | rest ]], vocabluary, [ hit | entities ])
      end
    end
  end  
  
  @doc """
  Calls the generic get with stw-vocabluary.
  """
  def get(text, :stw) do
    get(text, @stwvoc)
  end
  
  @doc """
  Calls the generic get with swp-vocabluary.
  """
  def get(text, :swp) do
    get(text, @swpvoc)
  end
    
  @doc """
  Calls the generic get with swp-vocabluary.
  """
  def get(text, :ccs) do
    get(text, @ccsvoc)
  end
  
  @doc """
  Gets a binary, called text and a vocabluary.
  This function finds all appearances of words from the vocabluary that are in the text; it returns
  a list for each match, containing the matching string with its coresponding concept-id. 
  Result is a list of lists.
  """
  def get(text, vocabluary) when is_binary(text) do
    text
    |> prep_text
    |> detect(vocabluary, [])
  end
  
  @doc """
  Scheduler interface for the get-method.
  """
  def get(scheduler) do
    send scheduler, { :ready, self }
    
    receive do
      { :process, data_link, out_fun, vocabluary } ->      
        result = File.read!(data_link)
        |> get(vocabluary)
        |> out_fun.(data_link)
        
        get(scheduler)
      { :shutdown } ->
        exit(:normal)
    end
  end

end
