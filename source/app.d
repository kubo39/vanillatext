import std.file;
import std.path;

import gio.Application : GioApplication = Application;
import gio.Menu;
import gio.MenuItem;
import gio.SimpleAction;
import gtk.Application;
import gtk.ApplicationWindow;
import gtk.FileChooserDialog;
import gtk.ScrolledWindow;
import gtk.TextView;

string runFileChooserDialog()
{
    auto dialog = new FileChooserDialog("Open file", null, FileChooserAction.OPEN);
    scope (exit) dialog.destroy();

    dialog.addButton("Cancel", ResponseType.CANCEL);
    dialog.addButton("Open", ResponseType.ACCEPT);

    if (dialog.run() == ResponseType.ACCEPT)
    {
        auto filename = dialog.getFilename();
        return filename;
    }
    else
    {
        return null;
    }
}

void open(string filename, Application application)
{
    auto window = new MainWindow(application);
    loadFile(filename, window);
    window.setTitle(filename.baseName);
}

void loadFile(string filename, ApplicationWindow window)
{
    auto content = filename.readText();
    auto scrolledWindow = cast(ScrolledWindow) window.getChild();
    auto textView = cast(TextView) scrolledWindow.getChild();
    auto buffer = textView.getBuffer();
    buffer.setText(content);
}

class MainWindow : ApplicationWindow
{
    this(Application application)
    {
        super(application);
        setTitle("Vanilla Text");
        setDefaultSize(800, 600);

        auto scrolledWindow = new ScrolledWindow;
        auto textView = new TextView;

        scrolledWindow.add(textView);
        add(scrolledWindow);

        auto copyAction = new SimpleAction("copy", null);
        copyAction.addOnActivate((action, parameter) {
                auto clipboard = textView.getClipboard(null);
                textView.getBuffer().copyClipboard(clipboard);
            });

        auto pasteAction = new SimpleAction("paste", null);
        pasteAction.addOnActivate((action, parameter) {
                auto clipboard = textView.getClipboard(null);
                auto buffer = textView.getBuffer();
                buffer.pasteClipboard(clipboard, null, textView.getEditable());
            });

        addAction(copyAction);
        addAction(pasteAction);
    }
}

void main(string[] args)
{
    auto application = new Application("com.github.kubo39.vanilla-text", ApplicationFlags.FLAGS_NONE);

    application.addOnStartup((GioApplication app) {
            auto newWindowAction = new SimpleAction("new_window", null);
            newWindowAction.addOnActivate((action, parameter) {
                    auto window = new MainWindow(application);
                    window.showAll();
                });

            auto quitAction = new SimpleAction("quit", null);
            quitAction.addOnActivate((action, parameter) {
                    app.quit();
                });

            auto openAction = new SimpleAction("open", null);
            openAction.addOnActivate((action, parameter) {
                    auto file = runFileChooserDialog();
                    if (file !is null)
                    {
                        open(file, application);
                    }
                });

            application.addAction(newWindowAction);
            application.addAction(quitAction);
            application.addAction(openAction);

            auto menubar = new Menu;

            auto submenuFile = new Menu;
            auto newWindow = new MenuItem("New Window", "app.new_window");
            auto quit = new MenuItem("Quit", "app.quit");
            auto open = new MenuItem("Open", "app.open");

            submenuFile.appendItem(newWindow);
            submenuFile.appendItem(quit);
            submenuFile.appendItem(open);

            auto submenuEdit = new Menu;
            auto copy = new MenuItem("Copy", "win.copy");
            auto paste = new MenuItem("Paste", "win.paste");

            submenuEdit.appendItem(copy);
            submenuEdit.appendItem(paste);

            menubar.appendSubmenu("File", submenuFile);
            menubar.appendSubmenu("Edit", submenuEdit);

            application.setMenubar(menubar);
        });

    application.addOnActivate((GioApplication app) {
            auto window = new MainWindow(application);
            window.showAll();
        });

    application.run(args);
}
