from typing import List
from pathlib import Path
import re

def find_all_srcs() -> List[Path]:
    return list(Path('src').rglob('*.zig'))

def trim_after_element[T](xs: List[T], e: T) -> List[T]:
    return xs[:xs.index(e)] if e in xs else xs

def trim_before_element[T](xs: List[T], e: T) -> List[T]:
    return xs[xs.index(e) + 1:] if e in xs else xs

def general_sort(imports: List[List[str]]):
    imports.sort()

def groups_to_zig_code(groups: List[str]) -> str:
    if groups[2] == None:
        return f'const {groups[0]} = @import("{groups[1]}");'
    else:
        return f'const {groups[0]} = @import("{groups[1]}").{groups[2]};'

for file in find_all_srcs():
    print(file)

    lines: List[str] = []

    with open(file, "r") as f:
        lines = f.readlines()

    lines = list(
        map(
            lambda x: 
                x.removesuffix("\n"), 
            lines
        )
    )

    reg = re.compile(r"const (\w+) = @import\(\"(.+)\"\)(?:\.(\w+))?;")
    imports: List[List[str]] = list(
        map(
            lambda x: 
                reg.match(x).groups(), 
            trim_after_element(lines, "")
        )
    )

    imports_with_assignment: List[List[str]] = list(
        filter(
            lambda x: x[2] != None, 
            imports
        )
    )
    general_sort(imports_with_assignment)

    imports_self_type: List[List[str]] = list(
        filter(
            lambda x: 
                x[1].count(x[0]) > 0 and x[0][0].isupper(), 
            imports
        )
    )
    general_sort(imports_self_type)

    imports_modules: List[List[str]] = list(
        filter(
            lambda x: 
                x[1].count(x[0]) > 0 and x[0][0].islower() and x[1].count(".zig") == 0, 
            imports
        )
    )
    general_sort(imports_modules)

    imports_files: List[List[str]] = list(
        filter(
            lambda x: 
                x[1].count(x[0]) > 0 and x[0][0].islower() and x[1].count(".zig") > 0, 
            imports
        )
    )
    general_sort(imports_files)

    all_imports = imports_with_assignment + imports_self_type + imports_files + imports_modules
    all_imports_code: List[str] = list(map(groups_to_zig_code, all_imports))

    final_code = "\n".join(all_imports_code) + "\n\n" + "\n".join(trim_before_element(lines, ""))

    with open(file, "w") as f:
        f.write(final_code)

    break
