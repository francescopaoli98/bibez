import type { ReactNode } from 'react';
import type { ColorValue } from 'react-native';
import Svg, { Circle, Path, Rect } from 'react-native-svg';

export type IconName =
  | 'sun' | 'agenda' | 'calendar' | 'lists' | 'plus' | 'mic' | 'star' | 'clock'
  | 'chevronLeft' | 'chevronRight' | 'chevronDown' | 'check' | 'home' | 'list' | 'palette' | 'bell';

const SHAPES: Record<IconName, ReactNode> = {
  sun: (
    <>
      <Circle cx="12" cy="12" r="4" />
      <Path d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M5.6 18.4L7 17M17 7l1.4-1.4" />
    </>
  ),
  agenda: <Path d="M4 6h16M4 12h16M4 18h10" />,
  calendar: (
    <>
      <Rect x="3.5" y="5" width="17" height="15" rx="3" />
      <Path d="M3.5 10h17M8 3v4M16 3v4" />
    </>
  ),
  lists: <Path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01" />,
  list: <Path d="M8 6h12M8 12h12M8 18h12M4 6h.01M4 12h.01M4 18h.01" />,
  plus: <Path d="M12 5v14M5 12h14" />,
  mic: (
    <>
      <Rect x="9" y="3" width="6" height="12" rx="3" />
      <Path d="M5 11a7 7 0 0 0 14 0M12 18v3" />
    </>
  ),
  star: <Path d="M12 3.6l2.6 5.4 5.9.8-4.3 4.1 1.1 5.9L12 17l-5.3 2.8 1.1-5.9L3.5 9.8l5.9-.8z" />,
  clock: (
    <>
      <Circle cx="12" cy="12" r="9" />
      <Path d="M12 7v5l3 2" />
    </>
  ),
  chevronLeft: <Path d="M15 5l-7 7 7 7" />,
  chevronRight: <Path d="M9 5l7 7-7 7" />,
  chevronDown: <Path d="M5 9l7 7 7-7" />,
  bell: <Path d="M6 17V11a6 6 0 0 1 12 0v6l1.5 2h-15zM10 21h4" />,
  palette: (
    <>
      <Path d="M12 3a9 9 0 1 0 0 18c1.1 0 2-.9 2-2 0-.6-.3-1-.6-1.4-.3-.4-.4-.9-.4-1.3 0-1.1.9-2 2-2h2.3A3.7 3.7 0 0 0 21 10.6C21 6.4 17 3 12 3z" />
      <Circle cx="7.5" cy="11" r="1" />
      <Circle cx="10" cy="7.5" r="1" />
      <Circle cx="14.5" cy="7.5" r="1" />
    </>
  ),
  check: <Path d="M5 12.5l4.5 4.5L19 7.5" />,
  home: <Path d="M4 11l8-7 8 7M6 10v9h12v-9" />,
};

interface Props {
  name: IconName;
  size?: number;
  color: ColorValue;
  strokeWidth?: number;
  filled?: boolean;
}

export function Icon({ name, size = 24, color, strokeWidth = 2, filled = false }: Props) {
  return (
    <Svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={filled ? color : 'none'}
      stroke={color}
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {SHAPES[name]}
    </Svg>
  );
}
