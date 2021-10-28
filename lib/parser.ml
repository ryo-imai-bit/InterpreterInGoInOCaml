module Parser = struct
  include Lexer
  include Token
  include Ast

  type parser = {
    l: Lexer.lexer;
    curToken: Token.token;
    peekToken: Token.token;
    errors: string list;
  }

  let prefixPrecedence = 7
  let lowest = 1

  let precedence (tok:Token.token_type) = match tok with
  | Token.EQ
  | Token.NOT_EQ -> 2
  | Token.LT
  | Token.GT -> 3
  | Token.PLUS
  | Token.MINUS -> 4
  | Token.SLASH
  | Token.ASTERISK -> 5
  | Token.LPAREN -> 6
  | Token.LBRACKET -> 8
  | _ -> lowest

  let newParser lex = let (le, tok) = Lexer.nextToken lex
    in let (_, tk) = Lexer.nextToken le
      in {
            l = le;
            curToken = tok;
            peekToken = tk;
            errors = [];
        }

  let nextToken prs = let (le, _) = Lexer.nextToken prs.l
    in let (_, t) = Lexer.nextToken le in {
      l = le;
      curToken = prs.peekToken;
      peekToken = t;
      errors = prs.errors;
    }

  let parseToEnd prs = let rec toEnd pr = match pr.curToken with
  | {literal = _; t_type = Token.EOF} -> pr
  | _ -> toEnd pr
  in toEnd prs

  let peekPrecedence prs = precedence prs.peekToken.t_type

  let parseIntegerLiteral prs = (prs, Some (Ast.IntegerLiteral (int_of_string prs.curToken.literal)))

  let parseIdentifier prs = (prs, Some (Ast.Identifier prs.curToken.literal))

  let parseStringLiteral prs = (prs, Some (Ast.StringLiteral prs.curToken.literal))

  let errorParse prs tok = ({
    l = prs.l;
    curToken = prs.curToken;
    peekToken = prs.peekToken;
    errors = prs.errors @ [Token.tokenToString tok]
  }, None)

  (* stringもBANG, MINUSとくっついてしまう *)
  let rec parseExpression prs pcd = let parsePrefixExpression par = (match par.curToken with
  | {literal = _; t_type = Token.INT} -> parseIntegerLiteral par
  | {literal = _; t_type = Token.IDENT} -> parseIdentifier par
  | {literal = _; t_type = Token.STRING} -> parseStringLiteral par
  | {literal; t_type = Token.BANG}
  | {literal; t_type = Token.MINUS} -> (let (pr, exp) = parseExpression (nextToken par) prefixPrecedence
    in match exp with
    | Some ex -> (pr, Some (Ast.PrefixExpression {op = literal; right = ex}))
    | None -> (pr, None))
  | tok -> errorParse par tok)
  in let parseInfixExpression par lexp = match par.curToken with
  (* | {literal; t_type = Token.SLASH}
  | {literal; t_type = Token.ASTERISK}
  | {literal; t_type = Token.EQ} *)
  | {literal; t_type = Token.MINUS}
  | {literal; t_type = Token.PLUS} -> (match parseExpression (nextToken par) (precedence par.curToken.t_type) with
    | (pr, Some exp) -> (pr, Some (Ast.InfixExpression {tok = par.curToken; op = literal; left = lexp; right = exp;}))
    | (pr, None) -> (pr, None))
  | tok -> errorParse par tok
  in match parsePrefixExpression prs with
  | (ps, Some le) -> (if pcd < (peekPrecedence ps)
    then match (parseInfixExpression (nextToken ps) le) with
    | (pars, Some re) -> (pars, Some re)
    | (pars, None) -> (pars, None)
    else (ps, Some le))
  | (ps, None) -> (ps, None)

  (* let rec parsePrefixExpression prs = match prs.curToken with
  | {literal; t_type = Token.BANG}
  | {literal; t_type = Token.MINUS} -> (let (pr, exp) = parseExpression (nextToken prs) in match exp with
    | Some ex -> (pr, Ast.PrefixExpression {op = literal; right = ex})
    | None -> (pr, None))
  | tok -> errorParse prs tok *)

  let parseLetStatement prs = match prs.curToken with
  | {literal; t_type = Token.IDENT} -> let pr = nextToken prs in (match pr.curToken with
    | {literal = _; t_type = Token.ASSIGN} -> let (p, exp) = parseExpression (nextToken pr) lowest
      in (match exp with
      | Some e -> let sp = if Token.isSemicolon p.peekToken then nextToken p else p
          in (sp, Some (Ast.LetStatment {
              idt = Ast.Identifier literal;
              value = e
          }))
      | None -> (p, None))
    | tk -> errorParse pr tk)
  | tok -> errorParse prs tok

  let parseStatement prs = match prs.curToken with
  | {literal = "let"; t_type = Token.LET} -> nextToken prs |> parseLetStatement
  | _ -> (nextToken prs, Some Ast.ReturnStatement)
  (* let parseProgram _ _ = [Ast.LetStatment {idt = Ast.Identifier "a"; value = Ast.IntegerLiteral 1}] *)

  let parseProgram prs lst = let rec rpp prs prg = match prs.curToken with
  | {literal = _; t_type = Token.EOF} -> (prs, prg)
  | _ -> match parseStatement prs with
    | (ps, Some stm) -> rpp (nextToken ps) (prg@[stm])
    | (ps, None) -> (ps, prg)
  in rpp prs lst

  let eq prsa prsb = Token.eq prsa.curToken prsb.curToken && Token.eq prsa.peekToken prsb.peekToken

  let pp ppf prs = Fmt.pf ppf "Parser = { %s }" ("curToken:" ^ Token.tokenToString prs.curToken ^ " peekToken:" ^ Token.tokenToString prs.peekToken)
end