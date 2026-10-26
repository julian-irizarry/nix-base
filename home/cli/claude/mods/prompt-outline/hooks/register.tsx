import type { Register } from "claude-code";

// Prompts the person wrote; notifications and other agents' messages keep the engine's row.
const TYPED = new Set(["composer", "bridge", "sdk"]);

// Past this the engine's own row draws it: an outline gains nothing on a wall of text.
const MAX_CHARS = 20000;

export const register: Register = (on) => {
  on("ui.render", { component: "UserMessage" }, async ($, e, next) => {
    const { text, origin } = e.props;
    if (
      e.surface !== "terminal" ||
      !TYPED.has(origin.kind) ||
      text.length > MAX_CHARS ||
      !text.trim()
    ) {
      return next(e);
    }

    const { Box, Text } = $.ui.resolve(e);
    return (
      <Box flexDirection="column" alignItems="flex-start" marginTop={1}>
        <Box
          borderStyle="round"
          borderColor="gray"
          borderDimColor
          paddingX={1}
          flexShrink={1}
        >
          <Text>{text}</Text>
        </Box>
      </Box>
    );
  });
};
