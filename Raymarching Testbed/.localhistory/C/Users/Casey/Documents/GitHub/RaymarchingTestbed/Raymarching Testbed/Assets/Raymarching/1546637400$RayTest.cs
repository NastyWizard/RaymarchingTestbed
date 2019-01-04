using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ImageEffectAllowedInSceneView]
[ExecuteInEditMode]
public class RayTest : MonoBehaviour
{
    public Shader RayShader;

    private Material _mat;
    private Material mat
    {
        get
        {
            if (!_mat)
                _mat = new Material(Shader.Find("Hidden/RayTest"));
            return _mat;
        }
    }

    private Camera _currentCam;
    private Camera currentCam
    {
        get
        {
            if (!_currentCam)
                _currentCam = GetComponent<Camera>();
            return _currentCam;
        }
    }

    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {

        mat.SetMatrix("_Frustrum", GetFrustrum(currentCam));
        mat.SetMatrix("_InverseViewMatrix", currentCam.cameraToWorldMatrix);
        mat.SetVector("_CameraPos", currentCam.transform.position);

        GraphicsBlit(source, destination, mat);

    }

    private static void GraphicsBlit(RenderTexture source, RenderTexture dest, Material material, int pass = 0)
    {

        RenderTexture.active = dest;
        material.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho();

        material.SetPass(pass);

        GL.Begin(GL.QUADS);

        //BL
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);

        //BR
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);

        //TR
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);

        //TL
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();

    }

    private Matrix4x4 GetFrustrum(Camera cam)
    {
        float fov = cam.fieldOfView;
        float aspect = cam.aspect;

        Matrix4x4 frustum = Matrix4x4.identity;

        float halfFov = fov * .5f;

        float tanFov = Mathf.Tan(halfFov * Mathf.Deg2Rad);

        Vector3 toRight = Vector3.right * tanFov * aspect;
        Vector3 toTop = Vector3.up * tanFov;

        Vector3 topLeft = (-Vector3.forward - toRight + toTop);
        Vector3 topRight = (-Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);
        
        frustum.SetRow(0, topLeft);
        frustum.SetRow(1, topRight);
        frustum.SetRow(2, bottomRight);
        frustum.SetRow(3, bottomLeft);

        return frustum;
    }
}
