/*
 * Ext JS Library 1.1.1
 * Copyright(c) 2006-2007, Ext JS, LLC.
 * licensing@extjs.com
 * 
 * http://www.extjs.com/license
 */

Ext.XTemplate=function(){Ext.XTemplate.superclass.constructor.apply(this,arguments);var P=this.html;P=["<tpl>",P,"</tpl>"].join("");var O=/<tpl\b[^>]*>((?:(?=([^<]+))\2|<(?!tpl\b[^>]*>))*?)<\/tpl>/;var N=/^<tpl\b[^>]*?for="(.*?)"/;var L=/^<tpl\b[^>]*?if="(.*?)"/;var J=/^<tpl\b[^>]*?exec="(.*?)"/;var C,B=0;var G=[];while(C=P.match(O)){var M=C[0].match(N);var K=C[0].match(L);var I=C[0].match(J);var E=null,H=null,D=null;var A=M&&M[1]?M[1]:"";if(K){E=K&&K[1]?K[1]:null;if(E){H=new Function("values","parent","with(values){ return "+(Ext.util.Format.htmlDecode(E))+"; }")}}if(I){E=I&&I[1]?I[1]:null;if(E){D=new Function("values","parent","with(values){ "+(Ext.util.Format.htmlDecode(E))+"; }")}}if(A){switch(A){case".":A=new Function("values","parent","with(values){ return values; }");break;case"..":A=new Function("values","parent","with(values){ return parent; }");break;default:A=new Function("values","parent","with(values){ return "+A+"; }")}}G.push({id:B,target:A,exec:D,test:H,body:C[1]||""});P=P.replace(C[0],"{xtpl"+B+"}");++B}for(var F=G.length-1;F>=0;--F){this.compileTpl(G[F])}this.master=G[G.length-1];this.tpls=G};Ext.extend(Ext.XTemplate,Ext.Template,{re:/\{([\w-\.]+)(?:\:([\w\.]*)(?:\((.*?)?\))?)?\}/g,applySubTemplate:function(H,B,F){var E=this.tpls[H];if(E.test&&!E.test.call(this,B,F)){return""}if(E.exec&&E.exec.call(this,B,F)){return""}var G=E.target?E.target.call(this,B,F):B;F=E.target?B:F;if(E.target&&G instanceof Array){var C=[];for(var D=0,A=G.length;D<A;D++){C[C.length]=E.compiled.call(this,G[D],F)}return C.join("")}return E.compiled.call(this,G,F)},compileTpl:function(tpl){var fm=Ext.util.Format;var useF=this.disableFormats!==true;var sep=Ext.isGecko?"+":",";var fn=function(m,name,format,args){if(name.substr(0,4)=="xtpl"){return"'"+sep+"this.applySubTemplate("+name.substr(4)+", values, parent)"+sep+"'"}var v;if(name.indexOf(".")!=-1){v=name}else{v="values['"+name+"']"}if(format&&useF){args=args?","+args:"";if(format.substr(0,5)!="this."){format="fm."+format+"("}else{format="this.call(\""+format.substr(5)+"\", ";args=", values"}}else{args="";format="("+v+" === undefined ? '' : "}return"'"+sep+format+v+args+")"+sep+"'"};var body;if(Ext.isGecko){body="tpl.compiled = function(values, parent){ return '"+tpl.body.replace(/(\r\n|\n)/g,"\\n").replace(/'/g,"\\'").replace(this.re,fn)+"';};"}else{body=["tpl.compiled = function(values, parent){ return ['"];body.push(tpl.body.replace(/(\r\n|\n)/g,"\\n").replace(/'/g,"\\'").replace(this.re,fn));body.push("'].join('');};");body=body.join("")}eval(body);return this},applyTemplate:function(A){return this.master.compiled.call(this,A,{});var B=this.subs},apply:function(){return this.applyTemplate.apply(this,arguments)},compile:function(){return this}});Ext.XTemplate.from=function(A){A=Ext.getDom(A);return new Ext.XTemplate(A.value||A.innerHTML)};