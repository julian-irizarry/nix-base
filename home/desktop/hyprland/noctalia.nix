{
  config,
  lib,
  pkgs,
  noctalia,
  ...
}:

let
  cfg = config.my.desktop.hyprland;
in
lib.mkIf (cfg.enable && cfg.shell == "noctalia" && pkgs.stdenv.hostPlatform.isLinux) {
  programs.noctalia-shell = {
    enable = true;
    package = noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  xdg.configFile."noctalia/colorschemes/Pastel/Pastel.json".source = ./colorschemes/pastel.json;

  wayland.windowManager.hyprland.settings = {
    exec-once = lib.mkAfter [ "noctalia-shell" ];

    input = {
      touchpad = {
        natural_scroll = true;
      };
    };

    decoration = {
      rounding = 8;
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
    colorSchemes = {
      predefinedScheme = "Pastel";
      darkMode = true;
      useWallpaperColors = false;
      syncGsettings = true;
    };
    general = {
      telemetryEnabled = false;
      enableShadows = true;
      enableBlurBehind = true;
      reverseScroll = false;
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
      backgroundOpacity = 0.72;
      useSeparateOpacity = true;
      marginVertical = 0;
      marginHorizontal = 500;
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
            useDistroLogo = false;
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
            id = "MediaMini";
            hideMode = "hidden";
            hideWhenIdle = false;
            maxWidth = 145;
            useFixedWidth = false;
            scrollingMode = "hover";
            showAlbumArt = true;
            showProgressRing = true;
            showVisualizer = false;
            showArtistFirst = true;
            compactMode = false;
            panelShowAlbumArt = true;
            textColor = "none";
            visualizerType = "linear";
          }
          {
            id = "ActiveWindow";
            hideMode = "hidden";
            maxWidth = 145;
            useFixedWidth = false;
            scrollingMode = "hover";
            showIcon = true;
            showText = true;
            textColor = "none";
            colorizeIcons = false;
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
            id = "Volume";
            displayMode = "onhover";
            middleClickCommand = "pwvucontrol || pavucontrol";
            textColor = "none";
            iconColor = "none";
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
            id = "Brightness";
            iconColor = "none";
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
        ];
      };
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
