# Interesting Github repo

[Here](https://github.com/nix-gui/nix-gui)

## Information about flake templates

[Here](https://mulias.github.io/blog/nix-flakes-templates-good-actually/)

## Things to do....

In ZSH one can grab the last argument with '!!$' it would be great to have this
functionality in nushell

'!!<number of arguement>' will grab the argument of the number -- for example:

```
> ls workingFile/
> cp !!$testFileName newDir/NewTestFile
> rm !!1
```

The above would list the workingFile dir, then copy the file in that dir called
`testFileName` and then the final command would remove the original file in the
workingFile/ dir

item #0 in the array will grab the command not the arg
