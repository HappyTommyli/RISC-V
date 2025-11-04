from sympy import symbols, simplify_logic, parse_expr
from sympy.logic.boolalg import And, Or, Not

# 定义布尔变量
a, b, c, d = symbols('a b c d', boolean=True)

def simplify_boolean(expression_str):
    """
    化简布尔表达式
    :param expression_str: 输入表达式字符串（用&表示与，|表示或，~表示非）
    :return: 化简后的表达式字符串
    """
    # 解析表达式（将字符串转换为sympy的布尔表达式对象）
    # 映射运算符：& -> And, | -> Or, ~ -> Not
    expr = parse_expr(
        expression_str,
        local_dict={
            'And': And,
            'Or': Or,
            'Not': Not,
            'a': a, 'b': b, 'c': c, 'd': d
        },
        transformations='all'
    )
    
    # 化简表达式
    simplified_expr = simplify_logic(expr, form='dnf')  # dnf表示析取范式（更易读）
    return str(simplified_expr)

# 测试示例（使用之前讨论的表达式）
if __name__ == "__main__":
    # 示例1：化简 "a & b & c & d | ~a & c"（即abcd + nota and c）
    expr1 = "a & ( a | b )"
    print(f"原表达式1：{expr1}")
    print(f"化简后1：{simplify_boolean(expr1)}\n")
    
    # 示例2：化简 "a & c | ~c & d | a & b & d"（最初的表达式）
    expr2 = "a & c | ~c & d | a & b & d"
    print(f"原表达式2：{expr2}")
    print(f"化简后2：{simplify_boolean(expr2)}")
