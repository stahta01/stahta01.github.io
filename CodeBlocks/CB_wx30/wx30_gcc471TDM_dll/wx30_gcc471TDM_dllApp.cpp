/***************************************************************
 * Name:      wx30_gcc471TDM_dllApp.cpp
 * Purpose:   Code for Application Class
 * Author:     ()
 * Created:   2015-01-14
 * Copyright:  ()
 * License:
 **************************************************************/

#ifdef WX_PRECOMP
#include "wx_pch.h"
#endif

#ifdef __BORLANDC__
#pragma hdrstop
#endif //__BORLANDC__

#include "wx30_gcc471TDM_dllApp.h"
#include "wx30_gcc471TDM_dllMain.h"

IMPLEMENT_APP(wx30_gcc471TDM_dllApp);

bool wx30_gcc471TDM_dllApp::OnInit()
{
    wx30_gcc471TDM_dllFrame* frame = new wx30_gcc471TDM_dllFrame(0L, _("wxWidgets Application Template"));
    frame->SetIcon(wxICON(aaaa)); // To Set App Icon
    frame->Show();
    
    return true;
}
