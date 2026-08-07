#!/usr/bin/env python3
"""
PDF转图片命令行工具
====================
打包后生成PDF转图片.exe，支持外部程序调用(C#/Python/bat)

【调用格式】
1. 查询PDF总页数
    python PDF转图片.py info "PDF完整路径"
    PDF转图片.exe info "PDF完整路径"

2. PDF转图片，支持复杂页码表达式 "1-3,5,10,12-15"
    python PDF转图片.py convert "PDF完整路径" "页码表达式" [-o 输出目录]
    PDF转图片.exe convert "PDF完整路径" "页码表达式" [-o 输出目录]

【页码表达式语法】
    单页: 5
    区间: 1-3
    混合: "1-3,5,10,12-15"
    区间写反自动修正，自动去重、排序

【参数说明】
    info            查询页数子命令
    convert         转图片子命令
    PDF完整路径     pdf文件路径，中文/空格必须英文双引号包裹
    页码表达式      如 "1-3,5,10,12-15"，必须加英文双引号
    -o / --output   可选，输出文件夹；不存在自动创建；不填输出到pdf同目录

【返回退出码】
    0   执行成功
    1   失败：参数错误、文件打不开、页码越界、解析失败

【示例命令 PowerShell/CMD】
# 查询页数
python PDF转图片.py info "E:\SdT\第十讲(学生版).pdf"

# 转换1‑3,5,10,12‑15页，输出到pdf同目录
python PDF转图片.py convert "E:\SdT\第十讲(学生版).pdf" "1-3,5,10,12-15"

# 指定输出文件夹
python PDF转图片.py convert "E:\SdT\第十讲(学生版).pdf" "1-3,5" -o "E:\SdT\pdf_out"

【Nuitka打包命令】
python -m nuitka ^
--onefile ^
--include-module=pymupdf ^
--windows-console-mode=force ^
PDF转图片.py

⚠️注意：禁止使用--windows-disable-console，会丢失命令行参数与输出
⚠️页码表达式带逗号，必须套英文双引号 ""
"""

import sys
import os
import argparse
import pymupdf as fitz


def parse_page_expr(expr: str) -> list[int]:
    """
    解析页码表达式 "1-3,5,10,12-15" → [1,2,3,5,10,12,13,14,15]
    """
    pages = set()
    parts = expr.split(",")
    for part in parts:
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a_str, b_str = part.split("-", maxsplit=1)
            a = int(a_str.strip())
            b = int(b_str.strip())
            if a > b:
                a, b = b, a
            for p in range(a, b + 1):
                pages.add(p)
        else:
            p = int(part.strip())
            pages.add(p)
    result = sorted(list(pages))
    return result


def get_pdf_total_pages(pdf_path: str) -> int:
    doc = fitz.open(pdf_path)
    total = len(doc)
    doc.close()
    return total


def PDF_Pic(pdf_path: str, page_list: list[int], out_dir: str = None) -> str:
    pdf_basename = os.path.splitext(os.path.basename(pdf_path))[0]

    if out_dir is None:
        out_dir = os.path.dirname(pdf_path)
    else:
        os.makedirs(out_dir, exist_ok=True)

    doc = fitz.open(pdf_path)
    total_page = len(doc)

    # 校验所有页码
    for p in page_list:
        if p < 1 or p > total_page:
            doc.close()
            return f"页码非法！请求页码:{p}，文档总页数：{total_page}"

    for pg_num in page_list:
        idx = pg_num - 1
        page = doc[idx]
        zoom = int(100)
        rotate = int(0)
        H = 20
        M = 40
        L = 60
        trans = fitz.Matrix(zoom / M, zoom / M).prerotate(rotate)
        pm = page.get_pixmap(matrix=trans, alpha=True)
        out_filename = f"{pdf_basename}第{pg_num}页.png"
        out_file = os.path.join(out_dir, out_filename)
        pm.save(out_file)
        print(f"已生成：{out_file}")

    doc.close()
    return "\n操作完成!\n"


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="PDF转图片命令行工具 | 页码示例：1-3,5,10,12-15",
        epilog="""
示例：
查询页数：  python PDF转图片.py info "E:\\test.pdf"
转图片：   python PDF转图片.py convert "E:\\test.pdf" "1-3,5,10" -o "E:\\out"
        """
    )
    subparsers = parser.add_subparsers(dest="cmd", required=True, help="执行命令：info / convert")

    # info 查询页数： python PDF转图片.py info "pdf路径"
    parser_info = subparsers.add_parser("info", help="查询PDF总页数")
    parser_info.add_argument("pdf", help="PDF文件完整路径")

    # convert转图片
    parser_convert = subparsers.add_parser("convert", help="PDF转图片；页码表达式如：1-3,5,10,12-15")
    parser_convert.add_argument("pdf", help="PDF文件完整路径")
    parser_convert.add_argument("page_expr", help='页码表达式，例："1-3,5,10,12-15"')
    parser_convert.add_argument("-o", "--output", help="输出文件夹，不指定则输出到PDF同目录")

    args = parser.parse_args()

    if args.cmd == "info":
        try:
            total = get_pdf_total_pages(args.pdf)
            print(f"PDF总页数：{total}")
        except Exception as e:
            print(f"读取PDF失败：{e}")
            sys.exit(1)
        sys.exit(0)

    elif args.cmd == "convert":
        try:
            page_list = parse_page_expr(args.page_expr)
        except ValueError:
            print(f"页码表达式解析失败！示例格式：1-3,5,10,12-15")
            sys.exit(1)

        try:
            result = PDF_Pic(args.pdf, page_list, args.output)
            print(result)
        except Exception as e:
            print(f"运行出错：{e}")
            sys.exit(1)
        sys.exit(0)