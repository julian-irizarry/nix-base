{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.desktop.hyprland;
in
lib.mkIf (cfg.enable && cfg.shell == "noctalia" && pkgs.stdenv.hostPlatform.isLinux) {
  services.hypridle = lib.mkIf cfg.idle.enable {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof noctalia-shell && noctalia-shell ipc call lockScreen lock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = cfg.idle.lockTimeout;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = cfg.idle.displayOffTimeout;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    colors = {
      mPrimary = "#F0B6D0";
      mOnPrimary = "#0E0E10";
      mSecondary = "#C3AED6";
      mOnSecondary = "#0E0E10";
      mTertiary = "#8BD5CA";
      mOnTertiary = "#0E0E10";
      mError = "#F38BA8";
      mOnError = "#0E0E10";
      mSurface = "#0E0E10";
      mOnSurface = "#ECECF1";
      mSurfaceVariant = "#18181B";
      mOnSurfaceVariant = "#A1A1AA";
      mOutline = "#2A2A30";
      mShadow = "#000000";
      mHover = "#222226";
      mOnHover = "#ECECF1";
    };
    plugins = {
      sources = [
        {
          enabled = true;
          name = "Official Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        screen-recorder = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
        fancy-audiovisualizer = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
      version = 2;
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = lib.mkAfter [ "noctalia-shell" ];

    input = {
      touchpad = {
        natural_scroll = true;
      };
    };

    decoration = {
      rounding = 12;
      rounding_power = 2;
      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(1a1a1aee)";
      };
      blur.enabled = false;
    };

    general.border_size = 0;

    decoration.dim_inactive = true;
    decoration.dim_strength = 0.25;
  };

  programs.noctalia-shell.settings = {
    settingsVersion = 59;
    general = {
      telemetryEnabled = false;
      enableShadows = true;
      enableBlurBehind = true;
      reverseScroll = false;
      compactLockScreen = true;
      lockScreenBlur = 0.70;
      passwordChars = true;
      lockScreenAnimations = true;
      enableLockScreenCountdown = false;
    };
    ui = {
      fontDefault = "Fira Sans";
      fontFixed = "Fira Mono";
      fontDefaultScale = 1;
      fontFixedScale = 1;
      tooltipsEnabled = true;
      scrollbarAlwaysVisible = true;
      boxBorderEnabled = false;
      panelBackgroundOpacity = 0.93;
      translucentWidgets = false;
      panelsAttachedToBar = true;
      settingsPanelMode = "centered";
      settingsPanelSideBarCardStyle = false;
    };
    bar = {
      barType = "floating";
      position = "top";
      density = "default";
      showCapsule = false;
      capsuleOpacity = 1;
      capsuleColorKey = "none";
      widgetSpacing = 6;
      contentPadding = 2;
      fontScale = 1;
      enableExclusionZoneInset = true;
      backgroundOpacity = 0.95;
      useSeparateOpacity = true;
      marginVertical = 2;
      marginHorizontal = 385;
      frameThickness = 8;
      frameRadius = 12;
      outerCorners = false;
      displayMode = "always_visible";
      rightClickAction = "controlCenter";
      rightClickFollowMouse = true;
      widgets = {
        left = [
          {
            id = "Launcher";
            icon = "rocket";
            useDistroLogo = true;
            enableColorization = false;
            colorizeSystemIcon = "none";
            colorizeSystemText = "none";
            customIconPath = "";
            iconColor = "none";
          }
          {
            id = "Workspace";
            labelMode = "index";
            characterCount = 2;
            fontWeight = "bold";
            hideUnoccupied = false;
            showBadge = true;
            showLabelsOnlyWhenOccupied = false;
            pillSize = 0.6;
            focusedColor = "error";
            occupiedColor = "none";
            emptyColor = "none";
            unfocusedIconsOpacity = 1;
            colorizeIcons = false;
            iconScale = 0.8;
            showApplications = false;
            showApplicationsHover = false;
            enableScrollWheel = true;
            followFocusedScreen = false;
            groupedBorderOpacity = 1;
          }
          {
            id = "SystemMonitor";
            compactMode = true;
            diskPath = "/";
            showCpuUsage = true;
            showCpuTemp = true;
            showCpuFreq = false;
            showCpuCores = false;
            showMemoryUsage = true;
            showMemoryAsPercent = false;
            showSwapUsage = false;
            showGpuTemp = false;
            showDiskUsage = false;
            showDiskAvailable = false;
            showDiskUsageAsPercent = false;
            showLoadAverage = false;
            showNetworkStats = false;
            useMonospaceFont = true;
            usePadding = false;
            textColor = "none";
            iconColor = "none";
          }
          {
            id = "Spacer";
          }
          {
            id = "AudioVisualizer";
            visualizerType = "bars";
            width = 100;
            barWidth = 3;
            barSpacing = 2;
            barHeight = 20;
            barBrightness = 100;
            colorMode = "primary";
            useFading = true;
            hideWhenNoMedia = true;
          }
        ];
        center = [
          {
            id = "Clock";
            formatHorizontal = "HH:mm ddd, MMM dd";
            formatVertical = "HH mm - dd MM";
            tooltipFormat = "HH:mm ddd, MMM dd";
            clockColor = "none";
            useCustomFont = false;
            customFont = "";
          }
        ];
        right = [
          {
            id = "Spacer";
          }
          {
            id = "Volume";
            displayMode = "onhover";
            middleClickCommand = "pwvucontrol || pavucontrol";
            textColor = "none";
            iconColor = "none";
          }
          {
            id = "Brightness";
            iconColor = "primary";
          }
          {
            id = "Battery";
            displayMode = "graphic-clean";
            hideIfNotDetected = true;
            hideIfIdle = false;
            showPowerProfiles = false;
            showNoctaliaPerformance = false;
            deviceNativePath = "__default__";
          }
          {
            id = "plugin:screen-recorder";
            iconColor = "tertiary";
          }
          {
            id = "NotificationHistory";
            showUnreadBadge = true;
            hideWhenZero = false;
            hideWhenZeroUnread = false;
            unreadBadgeColor = "primary";
            iconColor = "none";
          }
          {
            id = "Settings";
            iconColor = "none";
          }
          {
            id = "ControlCenter";
            icon = "noctalia";
            useDistroLogo = false;
            enableColorization = false;
            colorizeSystemIcon = "none";
            colorizeSystemText = "none";
            colorizeDistroLogo = false;
            customIconPath = "";
          }
          {
            id = "SessionMenu";
            iconColor = "error";
          }
        ];
      };
    };
    sessionMenu = {
      largeButtonsStyle = false;
      position = "top_right";
      showHeader = true;
      showKeybinds = true;
      enableCountdown = false;
    };
    wallpaper = {
      enabled = true;
      directory = "${config.home.homeDirectory}/Pictures/wallpapers";
      viewMode = "recursive";
      wallpaperChangeMode = "random";
      fillMode = "crop";
      showHiddenFiles = true;
      sortOrder = "date_desc";
    };
    dock = {
      enabled = true;
    };
    notifications = {
      enabled = true;
      location = "top_right";
      lowUrgencyDuration = 3;
      normalUrgencyDuration = 8;
      criticalUrgencyDuration = 15;
    };
    appLauncher = {
      terminalCommand = "wezterm start --";
    };
  };
}
