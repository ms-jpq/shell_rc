from os.path import altsep, normpath, sep
from pathlib import Path
from typing import Any

from ranger.api.commands import Command  # type: ignore


class touch(Command):  # type: ignore[misc, no-any-unimported]
    def tab(self, _: Any) -> Any:
        return self._tab_directory_content()

    def execute(self) -> None:
        if not (name := self.rest(1)):
            self.fm.notify("touch: missing filename", bad=True)
            return

        cwd = Path(self.fm.thisdir.path)
        path = Path(normpath(cwd / Path(name).expanduser()))

        path.parent.mkdir(parents=True, exist_ok=True)
        if str(name).endswith((sep, altsep or sep)):
            path.mkdir(parents=True, exist_ok=True)
        else:
            path.touch()

        for directory in path.parents:
            self.fm.get_directory(str(directory)).load_content(schedule=False)
            if directory == cwd:
                break

        self.fm.select_file(str(path))
