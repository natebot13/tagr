# Tagr

Tagr is a file tagging tool. It uses a tiny protobuf format to store tagging information for all files within a directory.

All tags have a type, and therefore a value to go along with them. Currently the supported types are: Flag, Bool, String, Int, Float, and Ref. The value of a tag is useful for filtering using expressions.

Tag filtering is designed for simplicity, but can be as complicated as you need. When filtering, the query is turned into a logical expression to evaluate against the value of tha named tag. Queries can be any number of expressions, separated by spaces, which are 'and'ed together for filter files. Also, math expressions and a variety of functions are available (coming from [EvalEx](https://github.com/RobluScouting/EvalEx])) for very specific filtering.

## Supported Query Features and examples:

- [x] simple tag search: 'dogs', 'cats dogs'
  - Finds files with the tag, no matter the value
- [x] quoted text for tags with spaces: 'people "Japan Trip"'
  - Since tags can be any string, use quotes in case the has spaces
- [x] negative terms: '-people dogs'
  - explicitly ignores files with the negated tags
- [x] expressions: 'dogs:1', 'cats:>5', 'amount_of_pie:<2*PI/3
  - the value of the tag is turned into an expression with the parameter after the colon.
- [x] #tags meta query: '#tags', '#tags:>3'
  - queries for the number of tags on the file
- [x] #modified meta query: '#modified:>NOW()-DAYS(30)'
  - queries for the last modified time of the file. Useful with expressions to find files with some time
- [x] path terms: '/memes', '/memes /download'
  - Finds files such that any part of their path contains the queried path. (i.e. if there's memes/ and images/memes/, the query '/memes' would capture both)
- [x] extension terms: '.png', '.gif'
  - search for any specific extension
- [x] any combination of the above: 'dogs -people cats:>1 /memes .gif'
  - all terms are logically 'AND'ed together, such that every term must be true to match a file
- [ ] tag comparison: TBD
  - Unimplemented, but something like searching for files with more cats than dogs would be cool.
