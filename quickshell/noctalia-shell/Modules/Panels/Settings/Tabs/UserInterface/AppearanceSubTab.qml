import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL
  Layout.fillWidth: true

  NToggle {
    label: I18n.tr("panels.user-interface.tooltips-label")
    description: I18n.tr("panels.user-interface.tooltips-description")
    checked: Settings.data.ui.tooltipsEnabled
    defaultValue: Settings.getDefaultValue("ui.tooltipsEnabled")
    onToggled: checked => Settings.data.ui.tooltipsEnabled = checked
  }

  NToggle {
    label: I18n.tr("panels.user-interface.box-border-label")
    description: I18n.tr("panels.user-interface.box-border-description")
    checked: Settings.data.ui.boxBorderEnabled
    defaultValue: Settings.getDefaultValue("ui.boxBorderEnabled")
    onToggled: checked => Settings.data.ui.boxBorderEnabled = checked
  }

  NToggle {
    label: I18n.tr("panels.user-interface.scrollbar-always-visible-label")
    description: I18n.tr("panels.user-interface.scrollbar-always-visible-description")
    checked: Settings.data.ui.scrollbarAlwaysVisible
    defaultValue: Settings.getDefaultValue("ui.scrollbarAlwaysVisible")
    onToggled: checked => Settings.data.ui.scrollbarAlwaysVisible = checked
  }

  NToggle {
    label: I18n.tr("panels.user-interface.shadows-label")
    description: I18n.tr("panels.user-interface.shadows-description")
    checked: Settings.data.general.enableShadows
    defaultValue: Settings.getDefaultValue("general.enableShadows")
    onToggled: checked => Settings.data.general.enableShadows = checked
  }

  NToggle {
    label: I18n.tr("panels.user-interface.blur-behind-label")
    description: I18n.tr("panels.user-interface.blur-behind-description")
    checked: Settings.data.general.enableBlurBehind
    defaultValue: Settings.getDefaultValue("general.enableBlurBehind")
    onToggled: checked => Settings.data.general.enableBlurBehind = checked
  }

  NToggle {
    label: I18n.tr("panels.user-interface.translucent-widgets-label")
    description: I18n.tr("panels.user-interface.translucent-widgets-description")
    checked: Settings.data.ui.translucentWidgets
    defaultValue: Settings.getDefaultValue("ui.translucentWidgets")
    onToggled: checked => Settings.data.ui.translucentWidgets = checked
  }

  NComboBox {
    visible: Settings.data.general.enableShadows
    label: I18n.tr("panels.user-interface.shadows-direction-label")
    description: I18n.tr("panels.user-interface.shadows-direction-description")
    Layout.fillWidth: true

    readonly property var shadowOptionsMap: ({
                                               "top_left": {
                                                 "name": I18n.tr("positions.top-left"),
                                                 "p": Qt.point(-2, -2)
                                               },
                                               "top": {
                                                 "name": I18n.tr("positions.top"),
                                                 "p": Qt.point(0, -3)
                                               },
                                               "top_right": {
                                                 "name": I18n.tr("positions.top-right"),
                                                 "p": Qt.point(2, -2)
                                               },
                                               "left": {
                                                 "name": I18n.tr("positions.left"),
                                                 "p": Qt.point(-3, 0)
                                               },
                                               "center": {
                                                 "name": I18n.tr("positions.center"),
                                                 "p": Qt.point(0, 0)
                                               },
                                               "right": {
                                                 "name": I18n.tr("positions.right"),
                                                 "p": Qt.point(3, 0)
                                               },
                                               "bottom_left": {
                                                 "name": I18n.tr("positions.bottom-left"),
                                                 "p": Qt.point(-2, 2)
                                               },
                                               "bottom": {
                                                 "name": I18n.tr("positions.bottom"),
                                                 "p": Qt.point(0, 3)
                                               },
                                               "bottom_right": {
                                                 "name": I18n.tr("positions.bottom-right"),
                                                 "p": Qt.point(2, 3)
                                               },
                                               "custom": {
                                                 "name": "Custom",
                                                 "p": Qt.point(Settings.data.general.shadowOffsetX || 0, Settings.data.general.shadowOffsetY || 4)
                                               }
                                             })

    model: Object.keys(shadowOptionsMap).map(function (k) {
      return {
        "key": k,
        "name": shadowOptionsMap[k].name
      };
    })

    currentKey: Settings.data.general.shadowDirection
    defaultValue: Settings.getDefaultValue("general.shadowDirection")

    onSelected: function (key) {
      var opt = shadowOptionsMap[key];
      if (opt && key !== "custom") {
        Settings.data.general.shadowDirection = key;
        Settings.data.general.shadowOffsetX = opt.p.x;
        Settings.data.general.shadowOffsetY = opt.p.y;
      }
    }
  }

  NDivider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
  }

  NValueSlider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
    label: "Shadow Intensity"
    description: "Opacity and darkness of drop shadows."
    from: 0.0
    to: 1.0
    stepSize: 0.05
    showReset: true
    value: Settings.data.general.shadowIntensity !== undefined ? Settings.data.general.shadowIntensity : 0.70
    defaultValue: 0.70
    onMoved: value => Settings.data.general.shadowIntensity = value
    text: Math.round((Settings.data.general.shadowIntensity !== undefined ? Settings.data.general.shadowIntensity : 0.70) * 100) + "%"
  }

  NDivider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
  }

  NValueSlider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
    label: "Shadow Blur Radius"
    description: "Softness and spread distance of shadow edges."
    from: 0
    to: 80
    stepSize: 2
    showReset: true
    value: Settings.data.general.shadowBlurMax !== undefined ? Settings.data.general.shadowBlurMax : 40
    defaultValue: 40
    onMoved: value => Settings.data.general.shadowBlurMax = Math.round(value)
    text: Math.round(Settings.data.general.shadowBlurMax !== undefined ? Settings.data.general.shadowBlurMax : 40) + " px"
  }

  NDivider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
  }

  NValueSlider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
    label: "Shadow Scale"
    description: "Size expansion of the shadow behind the surface."
    from: 1.00
    to: 1.15
    stepSize: 0.01
    showReset: true
    value: Settings.data.general.shadowScale !== undefined ? Settings.data.general.shadowScale : 1.00
    defaultValue: 1.00
    onMoved: value => Settings.data.general.shadowScale = value
    text: Math.round((Settings.data.general.shadowScale !== undefined ? Settings.data.general.shadowScale : 1.00) * 100) + "%"
  }

  NDivider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
  }

  NValueSlider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
    label: "Shadow Offset X"
    description: "Horizontal displacement of drop shadows."
    from: -20
    to: 20
    stepSize: 1
    showReset: true
    value: Settings.data.general.shadowOffsetX !== undefined ? Settings.data.general.shadowOffsetX : 0
    defaultValue: 0
    onMoved: value => {
      Settings.data.general.shadowOffsetX = Math.round(value);
      Settings.data.general.shadowDirection = "custom";
    }
    text: (Settings.data.general.shadowOffsetX !== undefined ? Settings.data.general.shadowOffsetX : 0) + " px"
  }

  NDivider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
  }

  NValueSlider {
    visible: Settings.data.general.enableShadows
    Layout.fillWidth: true
    label: "Shadow Offset Y"
    description: "Vertical displacement of drop shadows."
    from: -20
    to: 20
    stepSize: 1
    showReset: true
    value: Settings.data.general.shadowOffsetY !== undefined ? Settings.data.general.shadowOffsetY : 4
    defaultValue: 4
    onMoved: value => {
      Settings.data.general.shadowOffsetY = Math.round(value);
      Settings.data.general.shadowDirection = "custom";
    }
    text: (Settings.data.general.shadowOffsetY !== undefined ? Settings.data.general.shadowOffsetY : 4) + " px"
  }

  NDivider {
    Layout.fillWidth: true
  }

  NValueSlider {
    Layout.fillWidth: true
    label: I18n.tr("panels.user-interface.scaling-label")
    description: I18n.tr("panels.user-interface.scaling-description")
    from: 0.8
    to: 1.2
    stepSize: 0.05
    showReset: true
    value: Settings.data.general.scaleRatio
    defaultValue: Settings.getDefaultValue("general.scaleRatio")
    onMoved: value => Settings.data.general.scaleRatio = value
    text: Math.floor(Settings.data.general.scaleRatio * 100) + "%"
  }

  NDivider {
    Layout.fillWidth: true
  }

  NValueSlider {
    Layout.fillWidth: true
    label: I18n.tr("panels.user-interface.box-border-radius-label")
    description: I18n.tr("panels.user-interface.box-border-radius-description")
    from: 0
    to: 2
    stepSize: 0.01
    showReset: true
    value: Settings.data.general.radiusRatio
    defaultValue: Settings.getDefaultValue("general.radiusRatio")
    onMoved: value => Settings.data.general.radiusRatio = value
    text: Math.floor(Settings.data.general.radiusRatio * 100) + "%"
  }

  NValueSlider {
    Layout.fillWidth: true
    label: I18n.tr("panels.user-interface.control-border-radius-label")
    description: I18n.tr("panels.user-interface.control-border-radius-description")
    from: 0
    to: 2
    stepSize: 0.01
    showReset: true
    value: Settings.data.general.iRadiusRatio
    defaultValue: Settings.getDefaultValue("general.iRadiusRatio")
    onMoved: value => Settings.data.general.iRadiusRatio = value
    text: Math.floor(Settings.data.general.iRadiusRatio * 100) + "%"
  }

  NDivider {
    Layout.fillWidth: true
  }

  ColumnLayout {
    spacing: Style.marginL
    Layout.fillWidth: true

    NToggle {
      label: I18n.tr("panels.user-interface.animation-disable-label")
      description: I18n.tr("panels.user-interface.animation-disable-description")
      checked: Settings.data.general.animationDisabled
      defaultValue: Settings.getDefaultValue("general.animationDisabled")
      onToggled: checked => Settings.data.general.animationDisabled = checked
    }

    ColumnLayout {
      spacing: Style.marginXXS
      Layout.fillWidth: true
      visible: !Settings.data.general.animationDisabled

      NValueSlider {
        Layout.fillWidth: true
        label: I18n.tr("panels.user-interface.animation-speed-label")
        description: I18n.tr("panels.user-interface.animation-speed-description")
        from: 0
        to: 2.0
        stepSize: 0.01
        showReset: true
        value: Settings.data.general.animationSpeed
        defaultValue: Settings.getDefaultValue("general.animationSpeed")
        onMoved: value => Settings.data.general.animationSpeed = Math.max(value, 0.05)
        text: Math.round(Settings.data.general.animationSpeed * 100) + "%"
      }
    }
  }
}
