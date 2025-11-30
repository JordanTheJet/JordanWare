#!/usr/bin/env python3
import re
import sys

def fix_signal_asserts(filename):
    with open(filename, 'r') as f:
        content = f.read()

    # Find all functions and their signal monitors
    lines = content.split('\n')
    fixed_lines = []

    current_signal = None
    for i, line in enumerate(lines):
        # Check if this line creates a signal monitor
        monitor_match = re.search(r'var signal_monitor = monitor_signals\(microgame\)', line)
        if monitor_match:
            # Look back to find the function name to infer signal type
            for j in range(i-1, max(0, i-20), -1):
                func_match = re.search(r'func (test_\w+)', lines[j])
                if func_match:
                    func_name = func_match.group(1)
                    if 'win' in func_name or 'success' in func_name or 'click' in func_name:
                        current_signal = 'game_won'
                    elif 'lose' in func_name or 'collision' in func_name or 'fail' in func_name:
                        current_signal = 'game_lost'
                    break

        # Fix is_emitted() calls
        if current_signal and '.is_emitted()' in line:
            line = line.replace('.is_emitted()', f'.is_emitted("{current_signal}")')
            if 'await' not in line and 'assert_signal' in line:
                line = line.replace('assert_signal', 'await assert_signal')

        # Fix is_not_emitted() calls
        if current_signal and '.is_not_emitted()' in line:
            line = line.replace('.is_not_emitted()', f'.is_not_emitted("{current_signal}")')
            if 'await' not in line and 'assert_signal' in line:
                line = line.replace('assert_signal', 'await assert_signal')

        # Fix is_emitted(1) calls - the parameter is count, signal name is still needed
        if current_signal and re.search(r'\.is_emitted\(1\)', line):
            line = re.sub(r'\.is_emitted\(1\)', f'.is_emitted("{current_signal}")', line)
            if 'await' not in line and 'assert_signal' in line:
                line = line.replace('assert_signal', 'await assert_signal')

        fixed_lines.append(line)

    with open(filename, 'w') as f:
        f.write('\n'.join(fixed_lines))

if __name__ == '__main__':
    for filename in ['test_click_circle.gd', 'test_dodge_block.gd', 'test_microgame_base.gd']:
        fix_signal_asserts(filename)
        print(f"Fixed {filename}")
