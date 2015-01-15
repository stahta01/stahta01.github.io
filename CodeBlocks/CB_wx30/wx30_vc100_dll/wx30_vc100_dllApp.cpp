/***************************************************************
 * Name:      wx30_vc100_dllApp.cpp
 * Purpose:   Code for Application Class
 * Author:     ()
 * Created:   2015-01-15
 * Copyright:  ()
 * License:
 **************************************************************/

#ifdef WX_PRECOMP
#include "wx_pch.h"
#endif

#ifdef __BORLANDC__
#pragma hdrstop
#endif //__BORLANDC__

#include "wx30_vc100_dllApp.h"
#include "wx30_vc100_dllMain.h"

IMPLEMENT_APP(wx30_vc100_dllApp);

bool wx30_vc100_dllApp::OnInit()
{
    wx30_vc100_dllFrame* frame = new wx30_vc100_dllFrame(0L, _("wxWidgets Application Template"));
    frame->SetIcon(wxICON(aaaa)); // To Set App Icon
    frame->Show();
    
    return true;
}
