using UnityEngine;
using UnityEditor;

public class livetoonGUI : ShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {

        // マテリアルプロパティを取得
        MaterialProperty _TRANSPARENTMODE = FindProperty("_TRANSPARENTMODE", properties);

        // 変更を監視開始
        EditorGUI.BeginChangeCheck();


                // 既存のプロパティを描画
        base.OnGUI(materialEditor, properties);


        // 変更があった場合
        if (EditorGUI.EndChangeCheck())
        {
            // 対象の全マテリアルに対して
            foreach (Material m in materialEditor.targets)
            {
                // _TRANSMODEの値によって設定を切り替え
                switch (_TRANSPARENTMODE.floatValue)
                {
                    case 0: // 不透明
                        m.SetInt("_BleModSour", 1);
                        m.SetInt("_BleModDest", 0);
                        m.SetInt("_ZTeForLiOpa", 3);
                        m.SetOverrideTag("RenderType", "");
                        m.renderQueue = 2225;
                        break;

                    case 1: // 透明
                        m.SetInt("_BleModSour", 5);
                        m.SetInt("_BleModDest", 10);
                        m.SetInt("_ZTeForLiOpa", 4);
                        m.SetOverrideTag("RenderType", "Transparent");
                        m.renderQueue = 3000;
                        break;

                    default:
                        break;
                }
            }
        }
    }
}