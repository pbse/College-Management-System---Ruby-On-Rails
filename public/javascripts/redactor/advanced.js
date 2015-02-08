if (typeof RedactorPlugins == "undefined") var RedactorPlugins = {};
RedactorPlugins.advanced = {
    init: function () {
        
        var e = j.proxy(function () {
            j("#redactor_modal #latexp-link").click(j.proxy(function () {
                return MathJax.Hub.Queue(["Typeset", MathJax.Hub]), this.insertFromLatexp(), !1
            }, this)), j("#redactor_modal .latexp-preview-btn").click(j.proxy(function () {
                return this.generateLatexPreview(), !1
            }, this))
        }, this);
        console.log(this);
        this.buttonAdd("latex", "Insert equation (Tex)", j.proxy(function () {
            this.modalInit("Insert Tex expression", "#latex", 500, e), selection = j('.redactor_box > textarea').data("redactor").getSelection(), max = Math.max(selection.anchorOffset, selection.focusOffset), min = Math.min(selection.anchorOffset, selection.focusOffset), sel = selection.focusNode.data.slice(min, max), tex = sel.replace(/\~/g, ""), sel.split("~~").length == 3 && j("#redactor_modal_inner .latex-expression").val(tex)
        }, this))
    },
    generateLatexPreview: function () {
        exp = j("#redactor_modal .latex-expression").val(), j("#redactor_modal_inner .latex-preview-output").html("$$ " + exp + " $$"), s = MathJax.Hub.Queue(["Typeset", MathJax.Hub])
    },
    insertFromLatexp: function (e) {
        exp = j("#redactor_modal .latex-expression").val(), data = "~~" + exp + "~~", this.execCommand("inserthtml", data), this.modalClose()
    }
}