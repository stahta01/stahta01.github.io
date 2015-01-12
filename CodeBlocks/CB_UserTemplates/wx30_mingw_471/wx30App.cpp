/***************************************************************
 * Name:      wx30App.cpp
 * Purpose:   Code for Application Class
 * Author:     ()
 * Created:   2015-01-12
 * Copyright:  ()
 * License:
 **************************************************************/

#ifdef WX_PRECOMP
#include "wx_pch.h"
#endif

#ifdef __BORLANDC__
#pragma hdrstop
#endif //__BORLANDC__

#include "wx30App.h"
#include "wx30Main.h"

IMPLEMENT_APP(wx30App);

bool wx30App::OnInit()
{
    wx30Frame* frame = new wx30Frame(0L, _("wxWidgets Application Template"));
    frame->SetIcon(wxICON(aaaa)); // To Set App Icon
    frame->Show();
    
    return true;
}
