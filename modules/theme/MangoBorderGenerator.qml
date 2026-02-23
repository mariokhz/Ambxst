import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

QtObject {
    id: root

    function generate(Colors) {
        if (!Colors) return;

        const toHex = (c) => {
            const a = Math.round(c.a * 255).toString(16).padStart(2, '0');
            const r = Math.round(c.r * 255).toString(16).padStart(2, '0');
            const g = Math.round(c.g * 255).toString(16).padStart(2, '0');
            const b = Math.round(c.b * 255).toString(16).padStart(2, '0');
            return `${r}${g}${b}${a}`;
        }

        const primaryHex = toHex(Colors.primary);
        const overPrimaryHex = toHex(Colors.overPrimary);
        const secondaryHex = toHex(Colors.secondary);
        const tertiaryHex = toHex(Colors.tertiary);

        const conf = `focuscolor=0x${primaryHex}
maximizescreen=0x${overPrimaryHex}
scratchpadcolor=0x${secondaryHex}
globalcolor=0x${tertiaryHex}
`;

        const home = Quickshell.env("HOME");
        const mangoConfPath = home + "/.config/mango/ambxst/colors.conf";

        writer.text = conf;

        const cmd = `
            mkdir -p "$(dirname "${mangoConfPath}")" && \\
            echo "${conf}" > "${mangoConfPath}"
        `;

        writerProcess.command = ["sh", "-c", cmd];
        writerProcess.running = true;
    }

    property QtObject writer: QtObject {
        id: writer
        property string text
    }

    property Process writerProcess: Process {
        id: writerProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: console.log("MangoBorderGenerator: Colors generated.")
        }
        stderr: StdioCollector {
            onStreamFinished: (err) => {
                if (err) console.error("MangoBorderGenerator Error:", err);
            }
        }
    }
}
