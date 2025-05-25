final: prev: {
  mkSourceVersion =
    source: nightly:
    if nightly then
      (builtins.substring 0 7 source.revision)
    else
      (prev.removePrefix "v" source.version);
}
