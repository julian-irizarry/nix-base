/*
 * Shared type declarations for the sessionizer extension.
 * Preferences and arguments are the same regardless of launcher
 * (vicinae on Linux, raycast on Darwin).
 */

type ExtensionPreferences = {};

declare type Preferences = ExtensionPreferences;

declare namespace Preferences {
  /** Command: Sessionizer */
  export type Sessionizer = ExtensionPreferences & {};
  /** Command: Find Open Session */
  export type FindOpenSession = ExtensionPreferences & {};
}

declare namespace Arguments {
  /** Command: Sessionizer */
  export type Sessionizer = {};
  /** Command: Find Open Session */
  export type FindOpenSession = {};
}
