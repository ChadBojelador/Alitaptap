import React from 'react';
import logo from './images/logo.png';
import darkLogo from './images/darkmode-logo.png';
import { useTheme } from './ThemeContext';

export default function AlitaptapLogo({ size = 64 }) {
	const { theme } = useTheme();
	return (
		<img
			src={theme === 'dark' ? darkLogo : logo}
			alt="Alitaptap"
			width={size}
			height={size}
			style={{ objectFit: 'contain', display: 'inline-block', verticalAlign: 'middle' }}
		/>
	);
}
