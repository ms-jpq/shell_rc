from os.path import normpath
from pathlib import Path

from ranger.api.commands import Command  # type: ignore


class touch(Command):
    def tab(self, _) -> None:
        return self._tab_directory_content()

    def execute(self) -> None:
        if not (name := self.rest(1)):
            self.fm.notify("touch: missing filename", bad=True)
            return

        cwd = Path(self.fm.thisdir.path)
        path = Path(normpath(cwd / Path(name).expanduser()))
        directory = path.parent

        directory.mkdir(parents=True, exist_ok=True)
        path.touch()
        while True:
            self.fm.get_directory(str(directory)).load_content(schedule=False)
            if directory in (cwd, directory.parent):
                break
            directory = directory.parent

        self.fm.select_file(str(path))
