# aleph

**aleph** is a module for vocabluary-based named entity recognition: You read in a hierarchal-organized vocabluary (i. e. a thesaurus) and a text and **aleph** tells you which entities and concepts from the vocabluary appear in the text. 

It is necessary to read in the thesaurus as [SKOS](http://www.w3.org/2004/02/skos/) in n3- or turtle-format. The vocabluary is than transformed into a PATRICIA trie, using [this](https://github.com/okeuday/trie) excellent Erlang trie-implementation. Using a trie makes it unnecessary to further preprocess the input-text with stemming or lemmatization.

The **aleph** comes with build-in support for two well documented and curated vocabluaries: The [Standard Thesaurus Wirtschaft (STW)](http://zbw.eu/stw/versions/latest/about) that includes terms to describe the domain of economics and the [ACM Computer Classification System](http://www.acm.org/about/class/) which aims to describe the domain of computer science. 

## Examples

The following examples show how to use your own and the build-in vocabluaries.

Say, you would like to find all computer science related concepts that are mentioned in the first paragraph of the wikipedias article about computer science:

```bash
iex(1)> firstParagraph = "Computer science is the scientific and practical approach..."
iex(2)> Aleph.Entities.get(firstParagraph, :ccs) 
[{"design", "10011673"}, {"theory of computation", "10003752"},
 {"spec", "10011242"}, {"computer", "10003458"}, {"automating", "10003569"},
 {"computer science", "10003521"}, {"cell", "10011458"}, {"memory", "10010607"},
 {"computer", "10003458"}, {"procedures", "10011035"},
 {"computer science", "10003521"}]
```

As you can see this results into a list of tuples, where the first element denotes the entity and the second element the concepts unique descriptor-id. If you are only interested in the descriptors try this:

```bash
iex(3)> Aleph.Entities.get(firstParagraph, :ccs) |> Enum.map(fn { _syn, descriptor } -> descriptor end)
["10011673", "10003752", "10011242", "10003458", ... ]
```

To use the STW call the get-function in the following way: 

```bash
iex(4)> Aleph.Entities.get(yourText, :stw)
```

If you would like to use your own vocabluary, the following steps are required.

```bash
iex(5)> voc = Aleph.ParseTurtle.run("yourVocabluary.ttl") # or: Aleph.ParseNTriple.run("yourVocabluary.n3")
iex(6)> trie = trie = Aleph.VocabluaryTrie.get_vocabluary(voc)
iex(7)> Aleph.Entities.get(yourText, trie)
```



