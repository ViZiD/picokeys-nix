{ lib, ... }:
{
  flake.lib.genRomName =
    {
      pname,
      picoBoard,
      vidPid ? null,
      usbVid ? null,
      usbPid ? null,
      eddsaSupport ? null,
      version,
    }:
    lib.concatStringsSep "-" (
      [
        pname
        picoBoard
      ]
      ++ (lib.optional (vidPid != null) vidPid)
      ++ (lib.optional (usbVid != null && usbPid != null) (lib.toLower "${usbVid}_${usbPid}"))
      ++ (lib.optional eddsaSupport "eddsa")
      ++ (lib.singleton "v${version}")
    );
}
