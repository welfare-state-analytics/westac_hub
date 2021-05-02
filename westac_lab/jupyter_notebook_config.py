# FIXME #10 Deprecate this file since it's not used
import os

c = get_config()

c.NotebookApp.ip = u'0.0.0.0'
c.NotebookApp.port = os.environ.get('${LAB_PORT}', 8888)
c.NotebookApp.open_browser = False
c.FileContentsManager.delete_to_trash = False
