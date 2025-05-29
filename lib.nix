final: prev: {
  mkSourceVersion =
    source: latest:
    if latest then (builtins.substring 0 7 source.revision) else (prev.removePrefix "v" source.version);
}
