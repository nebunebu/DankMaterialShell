# Plugin System

The DMS shell includes an experimental plugin system that allows extending functionality through self-contained, dynamically-loaded QML components.

## Overview

The plugin system enables developers to create custom widgets that can be displayed in the DankBar alongside built-in widgets. Plugins are discovered, loaded, and managed through the **PluginService**, providing a clean separation between core shell functionality and user extensions.

## Architecture

### Core Components

1. **PluginService** (`Services/PluginService.qml`)
   - Singleton service managing plugin lifecycle
   - Discovers plugins from `$CONFIGPATH/DankMaterialShell/plugins/`
   - Handles loading, unloading, and state management
   - Provides data persistence for plugin settings

2. **PluginsTab** (`Modules/Settings/PluginsTab.qml`)
   - UI for managing available plugins
   - Access plugin settings

3. **PluginsTab Settings** (`Modules/Settings/PluginsTab.qml`)
   - Accordion-style plugin configuration interface
   - Dynamically loads plugin settings components inline
   - Provides consistent settings interface with proper focus handling

4. **DankBar Integration** (`Modules/DankBar/DankBar.qml`)
   - Renders plugin widgets in the bar
   - Merges plugin components with built-in widgets
   - Supports left, center, and right sections

## Plugin Structure

Each plugin must be a directory in `$CONFIGPATH/DankMaterialShell/plugins/` containing:

```
$CONFIGPATH/DankMaterialShell/plugins/YourPlugin/
├── plugin.json          # Required: Plugin manifest
├── YourWidget.qml       # Required: Widget component
├── YourSettings.qml     # Optional: Settings UI
├── qmldir               # Optional: QML module definition
└── *.js                 # Optional: JavaScript utilities
```

### Plugin Manifest (plugin.json)

The manifest file defines plugin metadata and configuration:

```json
{
    "id": "yourPlugin",
    "name": "Your Plugin Name",
    "description": "Brief description of what your plugin does",
    "version": "1.0.0",
    "author": "Your Name",
    "icon": "material_icon_name",
    "component": "./YourWidget.qml",
    "settings": "./YourSettings.qml",
    "dependencies": {
        "libraryName": {
            "url": "https://cdn.example.com/library.js",
            "optional": true
        }
    },
    "settings_schema": {
        "settingKey": {
            "type": "string|number|boolean|array|object",
            "default": "defaultValue"
        }
    },
    "permissions": [
        "settings_read",
        "settings_write"
    ]
}
```

**Required Fields:**
- `id`: Unique plugin identifier (camelCase, no spaces)
- `name`: Human-readable plugin name
- `component`: Relative path to widget QML file

**Optional Fields:**
- `description`: Short description of plugin functionality
- `version`: Semantic version string
- `author`: Plugin creator name
- `icon`: Material Design icon name
- `settings`: Path to settings component
- `dependencies`: External JS libraries
- `settings_schema`: Configuration schema
- `permissions`: Required capabilities

### Widget Component

The main widget component uses the **PluginComponent** wrapper which provides automatic property injection and bar integration:

```qml
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    // Define horizontal bar pill (optional)
    horizontalBarPill: Component {
        StyledRect {
            width: content.implicitWidth + Theme.spacingM * 2
            height: parent.widgetThickness
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            StyledText {
                id: content
                anchors.centerIn: parent
                text: "Hello World"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
            }
        }
    }

    // Define vertical bar pill (optional)
    verticalBarPill: Component {
        // Same as horizontal but optimized for vertical layout
    }

    // Define popout content (optional)
    popoutContent: Component {
        Column {
            width: parent.width
            spacing: Theme.spacingM
            padding: Theme.spacingM

            StyledText {
                text: "Popout Content"
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.surfaceText
            }
        }
    }

    // Popout dimensions (required if popoutContent is set)
    popoutWidth: 400
    popoutHeight: 300
}
```

**PluginComponent Properties (automatically injected):**
- `axis`: Bar axis information (horizontal/vertical)
- `section`: Bar section ("left", "center", "right")
- `parentScreen`: Screen reference for multi-monitor support
- `widgetThickness`: Recommended widget size perpendicular to bar
- `barThickness`: Bar thickness parallel to edge

**Component Options:**
- `horizontalBarPill`: Component shown in horizontal bars
- `verticalBarPill`: Component shown in vertical bars
- `popoutContent`: Optional popout window content
- `popoutWidth`: Popout window width
- `popoutHeight`: Popout window height

The PluginComponent automatically handles:
- Bar orientation detection
- Click handlers for popouts
- Proper positioning and anchoring
- Theme integration

### Settings Component

Optional settings UI loaded inline in the PluginsTab accordion interface. Use the simplified settings API with auto-storage components:

```qml
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "yourPlugin"

    StringSetting {
        settingKey: "apiKey"
        label: "API Key"
        description: "Your API key for accessing the service"
        placeholder: "Enter API key..."
    }

    ToggleSetting {
        settingKey: "notifications"
        label: "Enable Notifications"
        description: "Show desktop notifications for updates"
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "updateInterval"
        label: "Update Interval"
        description: "How often to refresh data"
        options: [
            {label: "1 minute", value: "60"},
            {label: "5 minutes", value: "300"},
            {label: "15 minutes", value: "900"}
        ]
        defaultValue: "300"
    }

    ListSetting {
        id: itemList
        settingKey: "items"
        label: "Saved Items"
        description: "List of configured items"
        delegate: Component {
            StyledRect {
                width: parent.width
                height: 40
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: Theme.surfaceText
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    width: 60
                    height: 28
                    color: removeArea.containsMouse ? Theme.errorHover : Theme.error
                    radius: Theme.cornerRadius

                    StyledText {
                        anchors.centerIn: parent
                        text: "Remove"
                        color: Theme.errorText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: removeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: itemList.removeItem(index)
                    }
                }
            }
        }
    }
}
```

**Available Setting Components:**

All settings automatically save on change and load on component creation. No manual `pluginService.savePluginData()` calls needed!

1. **PluginSettings** - Root wrapper for all plugin settings
   - `pluginId`: Your plugin ID (required)
   - Auto-handles storage and provides saveValue/loadValue to children
   - Place all other setting components inside this wrapper

2. **StringSetting** - Text input field
   - `settingKey`: Storage key (required)
   - `label`: Display label (required)
   - `description`: Help text (optional)
   - `placeholder`: Input placeholder (optional)
   - `defaultValue`: Default value (optional)
   - Layout: Vertical stack (label, description, input field)

3. **ToggleSetting** - Boolean toggle switch
   - `settingKey`: Storage key (required)
   - `label`: Display label (required)
   - `description`: Help text (optional)
   - `defaultValue`: Default boolean (optional)
   - Layout: Horizontal (label/description left, toggle right)

4. **SelectionSetting** - Dropdown menu
   - `settingKey`: Storage key (required)
   - `label`: Display label (required)
   - `description`: Help text (optional)
   - `options`: Array of `{label, value}` objects or simple strings (required)
   - `defaultValue`: Default value (optional)
   - Layout: Horizontal (label/description left, dropdown right)
   - Stores the `value` field, displays the `label` field

5. **ListSetting** - Manage list of items (manual add/remove)
   - `settingKey`: Storage key (required)
   - `label`: Display label (required)
   - `description`: Help text (optional)
   - `delegate`: Custom item delegate Component (optional)
   - `addItem(item)`: Add item to list
   - `removeItem(index)`: Remove item from list
   - Use when you need custom UI for adding items

6. **ListSettingWithInput** - Complete list management with built-in form
   - `settingKey`: Storage key (required)
   - `label`: Display label (required)
   - `description`: Help text (optional)
   - `fields`: Array of field definitions (required)
     - `id`: Field ID in saved object (required)
     - `label`: Column header text (required)
     - `placeholder`: Input placeholder (optional)
     - `width`: Column width in pixels (optional, default 200)
     - `required`: Must have value to add (optional, default false)
     - `default`: Default value if empty (optional)
   - Automatically generates:
     - Column headers from field labels
     - Input fields with placeholders
     - Add button with validation
     - List display showing all field values
     - Remove buttons for each item
   - Best for collecting structured data (servers, locations, etc.)

**Complete Settings Example:**

```qml
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "myPlugin"

    // Section header (optional)
    StyledText {
        width: parent.width
        text: "General Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    // Text input
    StringSetting {
        settingKey: "apiKey"
        label: "API Key"
        description: "Your service API key"
        placeholder: "sk-..."
        defaultValue: ""
    }

    // Toggle switches
    ToggleSetting {
        settingKey: "enabled"
        label: "Enable Feature"
        description: "Turn this feature on or off"
        defaultValue: true
    }

    // Dropdown selection
    SelectionSetting {
        settingKey: "theme"
        label: "Theme"
        description: "Choose your preferred theme"
        options: [
            {label: "Dark", value: "dark"},
            {label: "Light", value: "light"},
            {label: "Auto", value: "auto"}
        ]
        defaultValue: "dark"
    }

    // Structured list with multi-field input
    ListSettingWithInput {
        settingKey: "locations"
        label: "Locations"
        description: "Track multiple locations"
        fields: [
            {id: "name", label: "Name", placeholder: "Home", width: 150, required: true},
            {id: "timezone", label: "Timezone", placeholder: "America/New_York", width: 200, required: true}
        ]
    }
}
```

**Key Benefits:**
- Zero boilerplate - just define your settings
- Automatic persistence to `settings.json`
- Clean, consistent UI across all plugins
- No manual `pluginService` calls needed
- Proper layout and spacing handled automatically

## PluginService API

### Properties

```qml
PluginService.pluginDirectory: string
// Path to plugins directory ($CONFIGPATH/DankMaterialShell/plugins)

PluginService.availablePlugins: object
// Map of all discovered plugins {pluginId: pluginInfo}

PluginService.loadedPlugins: object
// Map of currently loaded plugins {pluginId: pluginInfo}

PluginService.pluginWidgetComponents: object
// Map of loaded widget components {pluginId: Component}
```

### Functions

```qml
// Plugin Management
PluginService.loadPlugin(pluginId: string): bool
PluginService.unloadPlugin(pluginId: string): bool
PluginService.reloadPlugin(pluginId: string): bool
PluginService.enablePlugin(pluginId: string): bool
PluginService.disablePlugin(pluginId: string): bool

// Plugin Discovery
PluginService.scanPlugins(): void
PluginService.getAvailablePlugins(): array
PluginService.getLoadedPlugins(): array
PluginService.isPluginLoaded(pluginId: string): bool
PluginService.getWidgetComponents(): object

// Data Persistence
PluginService.savePluginData(pluginId: string, key: string, value: any): bool
PluginService.loadPluginData(pluginId: string, key: string, defaultValue: any): any
```

### Signals

```qml
PluginService.pluginLoaded(pluginId: string)
PluginService.pluginUnloaded(pluginId: string)
PluginService.pluginLoadFailed(pluginId: string, error: string)
```

## Creating a Plugin

### Step 1: Create Plugin Directory

```bash
mkdir -p $CONFIGPATH/DankMaterialShell/plugins/MyPlugin
cd $CONFIGPATH/DankMaterialShell/plugins/MyPlugin
```

### Step 2: Create Manifest

Create `plugin.json`:

```json
{
    "id": "myPlugin",
    "name": "My Plugin",
    "description": "A sample plugin",
    "version": "1.0.0",
    "author": "Your Name",
    "icon": "extension",
    "component": "./MyWidget.qml",
    "settings": "./MySettings.qml",
    "permissions": ["settings_read", "settings_write"]
}
```

### Step 3: Create Widget Component

Create `MyWidget.qml`:

```qml
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    horizontalBarPill: Component {
        StyledRect {
            width: textItem.implicitWidth + Theme.spacingM * 2
            height: parent.widgetThickness
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            StyledText {
                id: textItem
                anchors.centerIn: parent
                text: "Hello World"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
            }
        }
    }

    verticalBarPill: Component {
        StyledRect {
            width: parent.widgetThickness
            height: textItem.implicitWidth + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            StyledText {
                id: textItem
                anchors.centerIn: parent
                text: "Hello"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                rotation: 90
            }
        }
    }
}
```

**Note:** Use `PluginComponent` wrapper for automatic property injection and bar integration. Define separate components for horizontal and vertical orientations.

### Step 4: Create Settings Component (Optional)

Create `MySettings.qml`:

```qml
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    pluginId: "myPlugin"

    StyledText {
        width: parent.width
        text: "Configure your plugin settings"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "text"
        label: "Display Text"
        description: "Text shown in the bar widget"
        placeholder: "Hello World"
        defaultValue: "Hello World"
    }

    ToggleSetting {
        settingKey: "showIcon"
        label: "Show Icon"
        description: "Display an icon next to the text"
        defaultValue: true
    }
}
```

### Step 5: Enable Plugin

1. Run the shell: `qs -p $CONFIGPATH/quickshell/dms/shell.qml`
2. Open Settings (Ctrl+,)
3. Navigate to Plugins tab
4. Click "Scan for Plugins"
5. Enable your plugin with the toggle switch
6. Add the plugin to your DankBar configuration

## Adding Plugin to DankBar

After enabling a plugin, add it to the bar:

1. Open Settings → Appearance → DankBar Layout
2. Add a new widget entry with your plugin ID
3. Choose section (left, center, right)
4. Save and reload

Or edit `$CONFIGPATH/quickshell/dms/config.json`:

```json
{
    "dankBarLeftWidgets": [
        {"widgetId": "myPlugin", "enabled": true}
    ]
}
```

## Best Practices

1. **Use Existing Widgets**: Leverage `qs.Widgets` components (DankIcon, DankToggle, etc.) for consistency
2. **Follow Theme**: Use `Theme` singleton for colors, spacing, and fonts
3. **Data Persistence**: Use PluginService data APIs instead of manual file operations
4. **Error Handling**: Gracefully handle missing dependencies and invalid data
5. **Performance**: Keep widgets lightweight, avoid expensive operations
6. **Responsive Design**: Adapt to `compactMode` and different screen sizes
7. **Clean Code**: Follow QML code conventions from CLAUDE.md
8. **Documentation**: Include README.md explaining plugin usage
9. **Versioning**: Use semantic versioning for updates
10. **Dependencies**: Document external library requirements

## Debugging

### Console Logging

View plugin logs:

```bash
qs -v -p $CONFIGPATH/quickshell/dms/shell.qml
```

Look for lines prefixed with:
- `PluginService:` - Service operations
- `PluginsTab:` - UI interactions
- `PluginsTab:` - Settings loading and accordion interface

### Common Issues

1. **Plugin Not Detected**
   - Check plugin.json syntax (use `jq` or JSON validator)
   - Verify directory is in `$CONFIGPATH/DankMaterialShell/plugins/`
   - Click "Scan for Plugins" in Settings

2. **Widget Not Displaying**
   - Ensure plugin is enabled in Settings
   - Add plugin ID to DankBar widget list
   - Check widget width/height properties

3. **Settings Not Loading**
   - Verify `settings` path in plugin.json
   - Check settings component for errors
   - Ensure plugin is enabled and loaded
   - Review PluginsTab console output for injection issues

4. **Data Not Persisting**
   - Confirm pluginService.savePluginData() calls (with injection)
   - Check `$CONFIGPATH/DankMaterialShell/settings.json` for pluginSettings data
   - Verify plugin has settings permissions
   - Ensure PluginService was properly injected into settings component

## Security Considerations

Plugins run with full QML runtime access. Only install plugins from trusted sources.

**Permissions System:**
- `settings_read`: Read plugin configuration
- `settings_write`: Write plugin configuration
- `process`: Execute system commands
- `network`: Network access

Future versions may enforce permission restrictions.

## API Stability

The plugin API is currently **experimental**. Breaking changes may occur in minor version updates. Pin to specific DMS versions for production use.

**Roadmap:**
- Plugin marketplace/repository
- Sandboxed plugin execution
- Enhanced permission system
- Plugin update notifications
- Inter-plugin communication

## Resources

- **Example Plugin**: https://github.com/rochacbruno/WorldClock
- **PluginService**: `Services/PluginService.qml`
- **Settings UI**: `Modules/Settings/PluginsTab.qml`
- **DankBar Integration**: `Modules/DankBar/DankBar.qml`
- **Theme Reference**: `Common/Theme.qml`
- **Widget Library**: `Widgets/`

## Contributing

Share your plugins with the community:

1. Create a public repository with your plugin
2. Include comprehensive README.md
4. Add example screenshots
5. Document dependencies and permissions

For plugin system improvements, submit issues or PRs to the main DMS repository.
